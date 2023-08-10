defmodule FarmbotOS.FarmwareRuntime do
  @moduledoc """
  Handles execution of Farmware plugins.
  """

  require Logger
  import FarmbotOS.Config, only: [get_config_value: 3]

  alias FarmbotOS.{Asset, JSON, Project, FarmwareLogger}
  alias FarmbotOS.Celery.AST
  alias FarmbotOS.FarmwareRuntime.{PipeWorker, RunCommand}
  alias FarmbotOS.BotState.{FileSystem, JobProgress.Percent}
  alias __MODULE__, as: State
  @packet_header_token 0xFBFB
  @packet_header_byte_size 10
  @error_timeout_ms 5000
  @pipe_dir "/tmp/farmware_runtime"
  @firmware_cmds %{
    "noop" => "noop.py",
    "camera-calibration" => "quickscripts/capture_and_calibrate.py",
    "plant-detection" => "quickscripts/capture_and_detect_coordinates.py",
    "historical-camera-calibration" => "quickscripts/download_and_calibrate.py",
    "historical-plant-detection" =>
      "quickscripts/download_and_detect_coordinates.py",
    "take-photo" => "take-photo/take_photo.py",
    "Measure Soil Height" => "measure-soil-height/measure_height.py"
  }
  # Default configs from the legacy manifest.json system, I think.
  @legacy_fallbacks %{
    "measured_distance" => "0",
    "disparity_search_depth" => "1",
    "disparity_block_size" => "15",
    "verbose" => "2",
    "log_verbosity" => "1",
    "calibration_factor" => "0",
    "calibration_disparity_offset" => "0",
    "calibration_image_width" => "0",
    "calibration_image_height" => "0",
    "calibration_measured_at_z" => "0",
    "calibration_maximum" => "0"
  }

  defstruct [
    :caller,
    :cmd,
    :mon,
    :context,
    :rpc,
    :scheduler_ref,
    :package,
    :start_time,
    :request_pipe,
    :request_pipe_handle,
    :response_pipe,
    :response_pipe_handle
  ]

  @opaque pipe_handle :: pid()

  @type t :: %State{
          caller: pid(),
          request_pipe: Path.t(),
          request_pipe_handle: pipe_handle,
          response_pipe: Path.t(),
          response_pipe_handle: pipe_handle,
          scheduler_ref: reference() | nil,
          package: String.t(),
          start_time: DateTime.t(),
          cmd: pid(),
          mon: pid() | nil,
          rpc: map(),
          context:
            :get_header
            | :get_payload
            | :process_payload
            | :send_response
            | :error
        }

  @doc "Start a Farmware"
  def start_link(package, env \\ %{}) do
    GenServer.start_link(__MODULE__, [package, env, self()],
      name: String.to_atom(package)
    )
  end

  @doc "Stop a farmware"
  def stop(pid) do
    Logger.info("Terminating farmware process")

    if Process.alive?(pid) do
      GenServer.stop(pid, :normal)
    end
  end

  def init([package, env, caller]) do
    File.mkdir_p(@pipe_dir)
    clause1 = String.slice(Ecto.UUID.generate(), 0..7)
    prefix = "#{package}-#{clause1}-farmware-"

    request_pipe = Path.join([@pipe_dir, prefix <> "request-pipe"])

    response_pipe = Path.join([@pipe_dir, prefix <> "response-pipe"])

    env = build_env(package, env, request_pipe, response_pipe)
    {:ok, req} = PipeWorker.start_link(request_pipe, :in)
    {:ok, resp} = PipeWorker.start_link(response_pipe, :out)
    python = System.find_executable("python")
    script = Path.join([dir(), Map.fetch!(@firmware_cmds, package)])

    opts = [
      env: env,
      cd: dir(package),
      into: FarmwareLogger.new(package)
    ]

    cmd_args = ["sh", ["-c", "#{python} #{script}"], opts]
    Logger.info(inspect(cmd_args))
    {cmd, _} = RunCommand.run(cmd_args)

    state = %State{
      caller: caller,
      cmd: cmd,
      mon: nil,
      context: :get_header,
      rpc: nil,
      scheduler_ref: nil,
      package: package,
      start_time: DateTime.utc_now(),
      request_pipe: request_pipe,
      request_pipe_handle: req,
      response_pipe: response_pipe,
      response_pipe_handle: resp
    }

    prog = %Percent{status: "Working", percent: 50, time: state.start_time}
    set_progress(state.package, prog)
    send(self(), :timeout)
    {:ok, state}
  end

  def terminate(_reason, state) do
    if state.cmd && Process.alive?(state.cmd),
      do: Process.exit(state.cmd, :kill)

    if state.request_pipe_handle do
      PipeWorker.close(state.request_pipe_handle)
    end

    if state.response_pipe_handle do
      PipeWorker.close(state.response_pipe_handle)
    end
  end

  def handle_info(msg, %{context: :error} = state) do
    Logger.warning("unhandled message in error state: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info(
        {:csvm_done, ref, {:error, reason}},
        %{scheduler_ref: ref} = state
      ) do
    send(state.caller, {:error, reason})
    {:noreply, %{state | scheduler_ref: nil, context: :error}}
  end

  def handle_info({:csvm_done, ref, :ok}, %{scheduler_ref: ref} = state) do
    result = %AST{kind: :rpc_ok, args: %{label: state.rpc.args.label}, body: []}

    ipc = add_header(result)
    _reply = PipeWorker.write(state.response_pipe_handle, ipc)
    # Make sure to `timeout` after this one to go back to the
    # get_header context. This will cause another rpc to be processed.
    send(self(), :timeout)
    {:noreply, %{state | rpc: nil, context: :get_header}}
  end

  # get_request does two reads. One to get the header,
  # and a second to get the entire binary payload.
  def handle_info(:timeout, %{context: :get_header} = state) do
    state = async_request_pipe_read(state, @packet_header_byte_size)
    {:noreply, state}
  end

  # Timeout set by `handle_packet/2`. This will mean the CSVM
  # didn't pick up the scheduled AST in a reasonable amount of time.
  def handle_info(:timeout, %{context: :process_request} = state) do
    Logger.error("Timeout waiting for #{inspect(state.rpc)} to be processed")
    send(state.caller, {:error, :rpc_timeout})
    {:noreply, %{state | context: :error}}
  end

  # farmware exit
  def handle_info(
        {:DOWN, _ref, :process, _pid, _reason},
        %{cmd: _cmd_pid} = state
      ) do
    Logger.debug("Farmware exit")
    prog = %Percent{status: "Complete", percent: 100, time: state.start_time}
    set_progress(state.package, prog)
    send(state.caller, {:error, :farmware_exit})
    {:noreply, %{state | context: :error}}
  end

  # successful result of an io:read/2 in :get_header context
  def handle_info(
        {PipeWorker, _ref,
         {:ok,
          <<@packet_header_token::size(16), _reserved::size(32),
            payload_size::integer-big-size(32)>>}},
        %{context: :get_header} = state
      ) do
    state = async_request_pipe_read(state, payload_size)
    {:noreply, %{state | context: :get_payload}}
  end

  # error result of an io:read/2 in :get_header context
  def handle_info(
        {PipeWorker, _ref, {:ok, data}},
        %{context: :get_header} = state
      ) do
    Logger.error("Bad header: #{inspect(data, base: :hex, limit: :infinity)}")
    send(state.caller, {:error, {:unhandled_packet, data}})
    {:noreply, %{state | context: :error}}
  end

  # error result of an io:read/2 in :get_header context
  def handle_info({PipeWorker, _ref, error}, %{context: :get_header} = state) do
    Logger.error("Bad header: #{inspect(error)}")
    send(state.caller, {:error, :bad_packet_header})
    {:noreply, %{state | context: :error}}
  end

  # successful result of an io:read/2 in :get_payload context
  def handle_info(
        {PipeWorker, _ref, {:ok, packet}},
        %{context: :get_payload} = state
      ) do
    handle_packet(packet, state)
  end

  # error result of an io:read/2 in :get_header context
  def handle_info({PipeWorker, _ref, error}, %{context: :get_payload} = state) do
    Logger.error("Bad payload: #{inspect(error)}")
    send(state.caller, {:error, :bad_packet_payload})
    {:noreply, %{state | context: :error}}
  end

  # Pipe reads are done async because reading will block the entire
  # process from receiving more messages as well as
  # prevent the processes from terminating.
  # this means if a Farmware never opens the pipe
  # (a valid use case), When the Farmware completes
  # the pipe will still be waiting for information
  # and prevent the pipes from closing.
  def async_request_pipe_read(state, size) do
    mon = PipeWorker.read(state.request_pipe_handle, size)
    %{state | mon: mon}
  end

  # When a packet arrives, buffer it until
  # the controlling process (the CSVM) picks it up.
  # there is a timeout for how long a packet will wait to be collected,
  # but no time limit to how long it will take to
  # process the packet.
  def handle_packet(packet, state) do
    with {:ok, data} <- JSON.decode(packet),
         {:ok, rpc} <- decode_ast(data) do
      ref = make_ref()
      Logger.debug("executing rpc from farmware: #{inspect(rpc)}")
      # todo(connor) replace this with StepRunner?
      FarmbotOS.Celery.execute(rpc, ref)

      {:noreply,
       %{state | rpc: rpc, scheduler_ref: ref, context: :process_request},
       @error_timeout_ms}
    else
      {:error, reason} ->
        send(state.caller, {:error, reason})
        {:noreply, %{state | context: :error}}
    end
  end

  def decode_ast(data) do
    try do
      case AST.decode(data) do
        %{kind: :rpc_request} = ast ->
          {:ok, ast}

        %{} = ast ->
          Logger.error("Got bad ast: #{inspect(ast)}")
          {:error, :bad_ast}
      end
    rescue
      _ -> {:error, :bad_ast}
    end
  end

  # RPC ENV is passed in to `start_link` and overwrites everything
  # except the `base` data.
  def build_env(package, rpc_env, request_pipe, response_pipe) do
    token = get_config_value(:string, "authorization", "token")
    images_dir = "/tmp/images"
    state_root_dir = Application.get_env(:farmbot, FileSystem)[:root_dir]
    python_path = [dir(package), dir()] |> Enum.join(":")

    base =
      @legacy_fallbacks
      |> Map.put("FARMWARE_API_V2_REQUEST_PIPE", request_pipe)
      |> Map.put("FARMWARE_API_V2_RESPONSE_PIPE", response_pipe)
      |> Map.put("FARMBOT_API_TOKEN", token)
      |> Map.put("FARMBOT_OS_IMAGES_DIR", images_dir)
      |> Map.put("FARMBOT_OS_VERSION", Project.version())
      |> Map.put("FARMBOT_OS_STATE_DIR", state_root_dir)
      |> Map.put("PYTHONPATH", python_path)

    Logger.info("=== PYTHONPATH: " <> inspect(python_path))

    Asset.list_farmware_env()
    |> Map.new(fn %{key: key, value: val} -> {key, val} end)
    |> Map.merge(rpc_env)
    |> Map.merge(base)
  end

  def add_header(%AST{} = rpc) do
    payload = rpc |> Map.from_struct() |> JSON.encode!()

    header =
      <<@packet_header_token::size(16)>> <>
        :binary.copy(<<0x00>>, 4) <> <<byte_size(payload)::big-size(32)>>

    header <> payload
  end

  def dir(), do: Application.app_dir(:farmbot, ["priv", "farmware"])
  def dir("camera-calibration"), do: dir("quickscripts")
  def dir("historical-camera-calibration"), do: dir("quickscripts")
  def dir("historical-plant-detection"), do: dir("quickscripts")
  def dir("Measure Soil Height"), do: dir("measure-soil-height")
  def dir("noop"), do: dir()
  def dir("plant-detection"), do: dir("quickscripts")
  def dir(dir_name), do: Path.join(dir(), dir_name)

  defp set_progress(name, percent) do
    percent2 = Map.put(percent, :type, "package")
    FarmbotOS.BotState.set_job_progress(job_name(name), percent2)
  end

  def job_name("camera-calibration"), do: "Calibrating camera"
  def job_name("historical-camera-calibration"), do: "Calibrating camera"
  def job_name("historical-plant-detection"), do: "Running weed detector"
  def job_name("plant-detection"), do: "Running weed detector"
  def job_name("take-photo"), do: "Taking photo"
  def job_name("Measure Soil Height"), do: "Measuring soil height"
  def job_name(package), do: "Executing #{package}"
end
