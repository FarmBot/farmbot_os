defmodule Farmbot.FarmwareRuntime do
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
      runtime_dir: "/var/run/farmbot"
    """)

  @packet_header_token 0xFBFB
  @packet_header_byte_size 10

  alias __MODULE__, as: State

  defstruct [
    :cmd,
    :context,
    :rpc,
    :request_pipe,
    :request_pipe_handle,
    :response_pipe,
    :response_pipe_handle
  ]

  @type file_handle ::
          {:file_descriptor, :prim_file,
           %{
             handle: reference(),
             owner: pid(),
             r_ahead_size: number,
             r_buffer: reference()
           }}

  @type t :: %State{
          request_pipe: Path.t(),
          request_pipe_handle: file_handle,
          response_pipe: Path.t(),
          response_pipe_handle: file_handle,
          cmd: pid(),
          rpc: map(),
          context: :get_request | :process_request | :send_response
        }

  def execute_script(package) do
    case Asset.get_farmware_manifest(package) do
      nil -> {:error, "Farmware not found"}
      manifest -> 
        case start_link(manifest) do
          {:ok, pid} -> GenServer.call(pid, :get_rpc)
          {:error, {:already_started, pid}} -> GenServer.call(pid, :get_rpc)
          _ -> {:error, "unknown Farmware error"}
        end
    end
  end

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
    # Create pipes
    {_, 0} = System.cmd("mkfifo", [request_pipe])
    {_, 0} = System.cmd("mkfifo", [response_pipe])
    # Open pipes
    {:ok, req} = :file.open(to_charlist(request_pipe), [:read, :write, :binary, :raw])
    {:ok, resp} = :file.open(to_charlist(response_pipe), [:read, :write, :binary, :raw])

    exec = System.find_executable(manifest.executable)
    installation_path = install_dir(manifest)

    opts = [
      env: env,
      cd: installation_path,
      into: IO.stream(:stdio, :line)
    ]

    # Start the plugin.
    cmd = spawn(MuonTrap, :cmd, [exec, manifest.args, opts])
    Process.monitor(cmd)

    state = %State{
      cmd: cmd,
      context: :get_request,
      rpc: nil,
      request_pipe: request_pipe,
      request_pipe_handle: req,
      response_pipe: response_pipe,
      response_pipe_handle: resp
    }

    {:ok, state, 0}
  end

  def terminate(_reason, state) do
    # Stop the Farmware if it's running
    if state.cmd && Process.alive?(state.cmd), do: Process.exit(state.cmd, :kill)
    # Stop the in/out pipes if they are open still
    if state.request_pipe_handle, do: :file.close(state.request_pipe_handle)
    if state.response_pipe_handle, do: :file.close(state.response_pipe_handle)
  end

  def handle_call(:get_rpc, _from, %{context: :process_request, rpc: rpc} = state) do
    {:reply, rpc, %{context: :send_response, rpc: nil}}
  end

  def handle_call(:get_rpc, _from, state) do
    {:reply, nil, state}
  end

  # get_request does two reads. One to get the header,
  # and a second to get the entire binary payload.
  def handle_info(:timeout, %{context: :get_request} = state) do
    case :file.read(state.request_pipe_handle, @packet_header_byte_size) do
      {:ok,
       <<@packet_header_token::size(16), _reserved::size(32), payload_size::integer-big-size(32)>>} ->
        {:ok, packet} = :file.read(state.request_pipe_handle, payload_size)
        handle_packet(packet, state)

      {:ok, unhandled} ->
        {:stop, {:unhandled_packet, unhandled}, state}

      {:error, reason} ->
        {:stop, {:error, reason}, state}
    end
  end

  # Timeout set by `handle_packet/2`. This will mean the CSVM
  # didn't pick up the scheduled AST in a reasonable amount of time.
  def handle_info(:timeout, %{context: :process_request} = state) do
    Logger.error("Timeout waiting for #{inspect(state.rpc)} to be processed")
    {:stop, {:error, :rpc_timeout}, state}
  end

  def hadnle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

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
      case Farmbot.CeleryScript.AST.decode(data) do
        %{kind: :rpc_request} = ast -> {:ok, ast}
        %{} = ast -> 
          Logger.error "Got bad ast: #{inspect(ast)}"
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
end
