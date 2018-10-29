defmodule Farmbot.FarmwareRuntime do
  import Farmbot.AssetWorker.Farmbot.Asset.FarmwareInstallation, only: [install_dir: 1]

  alias Farmbot.Asset
  alias Asset.FarmwareInstallation.Manifest
  alias Farmbot.FarmwareRuntime.PlugWrapper
  import Farmbot.Config, only: [get_config_value: 3]

  def execute_script(%{package: package} = args) do
    IO.inspect(args, label: "execute_script")

    case start_link(package) do
      {:ok, pid} -> await(pid)
      {:error, {:already_started, pid}} -> await(pid)
    end
  end

  def await(pid) do
    GenServer.call(pid, :await, :infinity)
  end

  def schedule(pid, ast) do
    GenServer.call(pid, {:schedule, ast}, :infinity)
  end

  def start_link(package) do
    GenServer.start_link(__MODULE__, [package], name: String.to_atom(package))
  end

  def init([package]) do
    _ = Plug.Cowboy.shutdown(PlugWrapper.HTTP)
    manifest = Asset.get_farmware_manifest(package)
    env = build_env(manifest)
    exec = System.find_executable(manifest.executable)
    installation_path = install_dir(manifest)

    opts = [
      :stream,
      :binary,
      :exit_status,
      :hide,
      :use_stdio,
      :stderr_to_stdout,
      args: manifest.args,
      env: env,
      cd: installation_path
    ]

    {:ok, http} =
      Plug.Cowboy.http(
        PlugWrapper,
        [
          manifest: manifest,
          runtime_pid: self()
          # token: to_string(Keyword.fetch!(env, 'FARMWARE_TOKEN'))
        ],
        port: 27347
      )

    port = Port.open({:spawn_executable, exec}, opts)
    {:ok, %{port: port, http: http, await: nil, schedule: nil}}
  end

  def terminate(_, _state) do
    IO.puts("farmware terminate")
    _ = Plug.Cowboy.shutdown(PlugWrapper.HTTP)
  end

  def handle_info({_port, {:exit_status, 0}}, state) do
    {:stop, :normal, try_reply(state, :ok)}
  end

  def handle_info({_port, {:exit_status, code}}, state) do
    {:stop, :normal, try_reply(state, {:error, "Farmware exit: #{code}"})}
  end

  def handle_info({_port, {:data, data}}, state) do
    handle_port_data(data)
    {:noreply, state}
  end

  def handle_call(:await, from, state) do
    if state.schedule do
      GenServer.reply(state.schedule, :ok)
    end

    {:noreply, %{state | await: from}}
  end

  def handle_call(:error, reason, state) do
    if state.schedule do
      IO.puts("Error")
      GenServer.reply(state.schedule, reason)
    end

    {:stop, :normal, %{state | schedule: nil}}
  end

  def handle_call({:schedule, ast}, from, state) do
    state = try_reply(%{state | schedule: from}, {:ok, ast})
    {:noreply, state}
  end

  def handle_port_data(data) do
    IO.puts(data)
  end

  defp try_reply(%{await: nil} = state, _reply), do: state

  defp try_reply(%{await: caller} = state, reply) do
    GenServer.reply(caller, reply)
    %{state | await: nil}
  end

  defp build_env(manifest) do
    token = get_config_value(:string, "authorization", "token")
    images_dir = "/tmp/images"
    installation_path = install_dir(manifest)

    base =
      Map.new()
      |> Map.put("API_TOKEN", token)
      |> Map.put("FARMWARE_TOKEN", token)
      |> Map.put("IMAGES_DIR", images_dir)
      |> Map.put("FARMWARE_URL", "http://localhost:27347/")
      |> Map.put("PYTHONPATH", installation_path)
      |> Map.put("FARMBOT_OS_VERSION", Farmbot.Project.version())

    Asset.list_farmware_env()
    |> Map.new(fn %{key: key, value: val} -> {key, val} end)
    |> Map.merge(base)
    |> Enum.map(fn {key, val} ->
      {to_charlist(key), to_charlist(val)}
    end)
  end
end
