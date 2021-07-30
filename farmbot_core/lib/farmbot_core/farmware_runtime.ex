defmodule FarmbotCore.FarmwareLogger do
  require Logger

  defstruct name: "UNKNOWN FARMARE?"
  def new(name), do: %__MODULE__{name: name}

  defimpl Collectable do
    alias FarmbotCore.FarmwareLogger, as: S

    def into(%S{} = logger), do: {logger, &collector/2}
    defp collector(%S{} = logger, :done), do: logger
    defp collector(%S{} = _, :halt), do: :ok
    defp collector(%S{} = logger, {:cont, text}) do
      Logger.debug("[#{inspect(logger.name)}] " <> text)
      logger
    end

  end
end

defmodule FarmbotCore.FarmwareRuntime do
  @moduledoc """
  Handles execution of Farmware plugins.
  """

  alias FarmbotCeleryScript.AST
  alias FarmbotCore.Asset.FarmwareInstallation.Manifest
  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmwareInstallation
  alias FarmbotCore.BotState.FileSystem
  alias FarmbotCore.FarmwareRuntime.PipeWorker
  alias FarmbotCore.Project
  import FarmwareInstallation, only: [install_dir: 1]

  alias FarmbotCore.{Asset, JSON}
  import FarmbotCore.Config, only: [get_config_value: 3]
  require Logger

  @error_timeout_ms 5000
  @runtime_dir "/tmp/farmware_runtime"

  @muontrap_opts Application.get_env(:farmbot_core, __MODULE__)[:muontrap_opts]
  @muontrap_opts @muontrap_opts || []

  @packet_header_token 0xFBFB
  @packet_header_byte_size 10

  alias __MODULE__, as: State

  defstruct [
    :caller,
    :cmd,
    :mon,
    :context,
    :rpc,
    :scheduler_ref,
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
          cmd: pid(),
          mon: pid() | nil,
          rpc: map(),
          context: :get_header | :get_payload | :process_payload | :send_response | :error
        }

  @doc "Start a Farmware"
  def start_link(%Manifest{} = manifest, env \\ %{}) do
    package = manifest.package
    GenServer.start_link(__MODULE__, [manifest, env, self()], name: String.to_atom(package))
  end

  @doc "Stop a farmware"
  def stop(pid) do
    Logger.info("Terminating farmware process")

    if Process.alive?(pid) do
      GenServer.stop(pid, :normal)
    end
  end

  def init([manifest, env, caller]) do
    package = manifest.package
    <<clause1::binary-size(8), _::binary>> = Ecto.UUID.generate()

    request_pipe =
      Path.join([
        @runtime_dir,
        package <> "-" <> clause1 <> "-farmware-request-pipe"
      ])

    response_pipe =
      Path.join([
        @runtime_dir,
        package <> "-" <> clause1 <> "-farmware-response-pipe"
      ])

    env = build_env(manifest, env, request_pipe, response_pipe)

    # Create pipe dir if it doesn't exist
    _ = File.mkdir_p(@runtime_dir)

    # Open pipes
    {:ok, req} = PipeWorker.start_link(request_pipe, :in)
    {:ok, resp} = PipeWorker.start_link(response_pipe, :out)

    exec = System.find_executable(manifest.executable)
    installation_path = install_dir(manifest)

    opts =
      Keyword.merge(@muontrap_opts,
        env: env,
        cd: installation_path,
        into: FarmbotCore.FarmwareLogger.new(package)
      )

    # Start the plugin.
    Logger.debug("spawning farmware: #{exec} #{manifest.args}")

    {cmd, _} = spawn_monitor(MuonTrap, :cmd, ["sh", ["-c", "#{exec} #{manifest.args}"], opts])

    state = %State{
      caller: caller,
      cmd: cmd,
      mon: nil,
      context: :get_header,
      rpc: nil,
      scheduler_ref: nil,
      request_pipe: request_pipe,
      request_pipe_handle: req,
      response_pipe: response_pipe,
      response_pipe_handle: resp
    }

    send(self(), :timeout)
    {:ok, state}
  end

  def terminate(_reason, state) do
    if state.cmd && Process.alive?(state.cmd), do: Process.exit(state.cmd, :kill)

    if state.request_pipe_handle do
      PipeWorker.close(state.request_pipe_handle)
    end

    if state.response_pipe_handle do
      PipeWorker.close(state.response_pipe_handle)
    end
  end

  def handle_info(msg, %{context: :error} = state) do
    Logger.warn("unhandled message in error state: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info({:csvm_done, ref, {:error, reason}}, %{scheduler_ref: ref} = state) do
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
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, %{cmd: _cmd_pid} = state) do
    Logger.debug("Farmware exit")
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
  def handle_info({PipeWorker, _ref, {:ok, data}}, %{context: :get_header} = state) do
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
  def handle_info({PipeWorker, _ref, {:ok, packet}}, %{context: :get_payload} = state) do
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
  defp async_request_pipe_read(state, size) do
    mon = PipeWorker.read(state.request_pipe_handle, size)
    %{state | mon: mon}
  end

  # When a packet arives, buffer it until
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
      FarmbotCeleryScript.execute(rpc, ref)

      {:noreply, %{state | rpc: rpc, scheduler_ref: ref, context: :process_request},
       @error_timeout_ms}
    else
      {:error, reason} ->
        send(state.caller, {:error, reason})
        {:noreply, %{state | context: :error}}
    end
  end

  defp decode_ast(data) do
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
  defp build_env(manifest, rpc_env, request_pipe, response_pipe) do
    token = get_config_value(:string, "authorization", "token")
    images_dir = "/tmp/images"
    installation_path = install_dir(manifest)
    state_root_dir = Application.get_env(:farmbot_core, FileSystem)[:root_dir]

    base =
      Map.new()
      |> Map.put("FARMWARE_API_V2_REQUEST_PIPE", request_pipe)
      |> Map.put("FARMWARE_API_V2_RESPONSE_PIPE", response_pipe)
      |> Map.put("FARMBOT_API_TOKEN", token)
      |> Map.put("FARMBOT_OS_IMAGES_DIR", images_dir)
      |> Map.put("FARMBOT_OS_VERSION", Project.version())
      |> Map.put("FARMBOT_OS_STATE_DIR", state_root_dir)
      |> Map.put("PYTHONPATH", installation_path)

    Asset.list_farmware_env()
    |> Map.new(fn %{key: key, value: val} -> {key, val} end)
    |> Map.merge(rpc_env)
    |> Map.merge(base)
  end

  defp add_header(%AST{} = rpc) do
    payload = rpc |> Map.from_struct() |> JSON.encode!()

    header =
      <<@packet_header_token::size(16)>> <>
        :binary.copy(<<0x00>>, 4) <> <<byte_size(payload)::big-size(32)>>

    header <> payload
  end
end
