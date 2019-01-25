defmodule Farmbot.FarmwareRuntime do
  @moduledoc """
  Handles execution of Farmware plugins. 
  """

  alias Farmbot.FarmwareRuntime.PipeWorker
  alias Farmbot.CeleryScript.AST
  alias Farmbot.AssetWorker.Farmbot.Asset.FarmwareInstallation
  alias Farmbot.Asset.FarmwareInstallation.Manifest
  import FarmwareInstallation, only: [install_dir: 1]

  alias Farmbot.{Asset, JSON}
  import Farmbot.Config, only: [get_config_value: 3]
  require Logger

  @error_timeout_ms 5000
  @runtime_dir Application.get_env(:farmbot_core, __MODULE__)[:runtime_dir]
  @runtime_dir ||
    Mix.raise("""
    config :farmbot_core, Farmbot.FarmwareRuntime,
      runtime_dir: "/tmp/farmware_runtime"
    """)

  @muontrap_opts Application.get_env(:farmbot_core, __MODULE__)[:muontrap_opts]
  @muontrap_opts || []

  @packet_header_token 0xFBFB
  @packet_header_byte_size 10

  alias __MODULE__, as: State

  defstruct [
    :cmd,
    :mon,
    :context,
    :rpc,
    :request_pipe,
    :request_pipe_handle,
    :response_pipe,
    :response_pipe_handle
  ]

  @opaque pipe_handle :: pid()

  @type t :: %State{
          request_pipe: Path.t(),
          request_pipe_handle: pipe_handle,
          response_pipe: Path.t(),
          response_pipe_handle: pipe_handle,
          cmd: pid(),
          mon: pid() | nil,
          rpc: map(),
          context: :get_header | :get_payload | :process_payload | :send_response
        }

  def stub(farmware_name) do
    manifest = Asset.get_farmware_manifest(farmware_name) || raise("not found")
    {:ok, pid} = Farmbot.FarmwareRuntime.start_link(manifest)
    Process.flag(:trap_exit, true)
    stub_loop(pid)
  end

  def stub_loop(pid) do
    receive do
      {:EXIT, ^pid, reason} -> reason
    after
      100 ->
        case Farmbot.FarmwareRuntime.process_rpc(pid) do
          {:ok, %{args: %{label: label}} = rpc} ->
            IO.puts("Stup processing #{inspect(rpc)}")
            response = %AST{kind: :rpc_ok, args: %{label: label}, body: []}
            true = Farmbot.FarmwareRuntime.rpc_processed(pid, response)
            stub_loop(pid)

          {:error, :no_rpc} ->
            stub_loop(pid)
        end
    end
  end

  @doc """
  Calls the Farmware Runtime asking for any RPCs that need to be
  processed. If an RPC was ready, the Farmware will not process
  any more RPCs until the current one is done.
  """
  def process_rpc(pid) do
    GenServer.call(pid, :process_rpc)
  end

  @doc """
  Calls the Farmware Runtime telling it that an RPC has been processed. 
  """
  def rpc_processed(pid, response) do
    GenServer.call(pid, {:rpc_processed, response})
  end

  @doc "Start a Farmware"
  def start_link(%Manifest{} = manifest) do
    package = manifest.package
    GenServer.start_link(__MODULE__, [manifest], name: String.to_atom(package))
  end

  def init([manifest]) do
    package = manifest.package

    request_pipe =
      Path.join([
        @runtime_dir,
        package <> "-" <> Ecto.UUID.generate() <> "-farmware-request-pipe"
      ])

    response_pipe =
      Path.join([
        @runtime_dir,
        package <> "-" <> Ecto.UUID.generate() <> "-farmware-response-pipe"
      ])

    env = build_env(manifest, request_pipe, response_pipe)

    # Create pipe dir if it doesn't exist
    _ = File.mkdir_p(@runtime_dir)

    # Open a pipe
    {:ok, req} = PipeWorker.start_link(request_pipe)
    {:ok, resp} = PipeWorker.start_link(response_pipe)

    exec = System.find_executable(manifest.executable)
    installation_path = install_dir(manifest)

    opts =
      Keyword.merge(@muontrap_opts,
        env: env,
        cd: installation_path,
        into: IO.stream(:stdio, :line)
      )

    # Start the plugin.
    {cmd, _} = spawn_monitor(MuonTrap, :cmd, [exec, manifest.args, opts])

    state = %State{
      cmd: cmd,
      mon: nil,
      context: :get_header,
      rpc: nil,
      request_pipe: request_pipe,
      request_pipe_handle: req,
      response_pipe: response_pipe,
      response_pipe_handle: resp
    }

    {:ok, state, 0}
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

  # If we are in the `process_request` state, send the RPC out to be buffered.
  # This moves us to the `send_response` state. (which has _no_ timeout) 
  def handle_call(:process_rpc, {pid, _} = _from, %{context: :process_request, rpc: rpc} = state) do
    # Link the calling process
    # so the Farmware can exit if the rpc never gets processed. 
    _ = Process.link(pid)
    {:reply, {:ok, rpc}, %{state | rpc: nil, context: :send_response}}
  end

  # If not in the `process_request` state, noop
  def handle_call(:process_rpc, _from, state) do
    {:reply, {:error, :no_rpc}, state}
  end

  def handle_call({:rpc_processed, result}, {pid, _} = _from, %{context: :send_response} = state) do
    # Unlink the calling process
    _ = Process.unlink(pid)
    ipc = add_header(result)
    reply = PipeWorker.write(state.response_pipe_handle, ipc)
    # Make sure to `timeout` after this one to go back to the 
    # get_header context. This will cause another rpc to be processed.
    {:reply, reply, %{state | rpc: nil, context: :get_header}, 0}
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
    {:stop, {:error, :rpc_timeout}, state}
  end

  # farmware exit
  def handle_info({:DOWN, _ref, :process, cmd, _reason}, %{cmd: cmd} = state) do
    Logger.debug("Farmware exit")
    {:stop, :normal, state}
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
    {:stop, {:unhandled_packet, data}, state}
  end

  # error result of an io:read/2 in :get_header context
  def handle_info({PipeWorker, _ref, error}, %{context: :get_header} = state) do
    Logger.error("Bad header: #{inspect(error)}")
    {:stop, error, state}
  end

  # successful result of an io:read/2 in :get_payload context
  def handle_info({PipeWorker, _ref, {:ok, packet}}, %{context: :get_payload} = state) do
    handle_packet(packet, state)
  end

  # error result of an io:read/2 in :get_header context
  def handle_info({PipeWorker, _ref, error}, %{context: :get_payload} = state) do
    Logger.error("Bad payload: #{inspect(error)}")
    {:stop, error, state}
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
      IO.inspect(rpc, label: "processing RPC")
      {:noreply, %{state | rpc: rpc, context: :process_request}, @error_timeout_ms}
    else
      error -> {:stop, error, state}
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

  defp build_env(manifest, request_pipe, response_pipe) do
    token = get_config_value(:string, "authorization", "token")
    images_dir = "/tmp/images"
    installation_path = install_dir(manifest)
    state_root_dir = Application.get_env(:farmbot_core, Farmbot.BotState.FileSystem)[:root_dir]

    base =
      Map.new()
      |> Map.put("FARMWARE_API_V2_REQUEST_PIPE", request_pipe)
      |> Map.put("FARMWARE_API_V2_RESPONSE_PIPE", response_pipe)
      |> Map.put("FARMBOT_API_TOKEN", token)
      |> Map.put("FARMBOT_OS_IMAGES_DIR", images_dir)
      |> Map.put("FARMBOT_OS_VERSION", Farmbot.Project.version())
      |> Map.put("FARMBOT_OS_STATE_DIR", state_root_dir)
      |> Map.put("PYTHONPATH", installation_path)

    Asset.list_farmware_env()
    |> Map.new(fn %{key: key, value: val} -> {key, val} end)
    |> Map.merge(base)
  end

  defp add_header(%AST{} = rpc) do
    payload = rpc |> Map.from_struct() |> JSON.encode!()

    header =
      <<@packet_header_token::size(16)>> <>
        :binary.copy(<<0x00>>, 4) <> <<byte_size(payload)::big-size(32)>>

    IO.puts("header size: #{byte_size(header)}")
    IO.inspect(header, label: "Header", base: :hex)
    header <> payload
  end
end
