defmodule Mix.Tasks.Farmbot.InjectSshKey do
  use Mix.Task

  def run([farmbot_node]) do
    farmbot_node = String.to_atom(farmbot_node)
    {:ok, _} = Node.start(:console)
    Node.set_cookie(:democookie)
    true = Node.connect(farmbot_node)

    key =
      Path.join(System.user_home!(), ".ssh/id_rsa.pub")
      |> File.read!()

    :ok = :rpc.call(farmbot_node, Application, :stop, [:ssh])
    :ok = :rpc.call(farmbot_node, Application, :stop, [:nerves_firmware_ssh])

    :ok =
      :rpc.call(farmbot_node, Application, :put_env, [
        :nerves_firmware_ssh,
        :authorized_keys,
        [key]
      ])

    {:ok, _} = :rpc.call(farmbot_node, Application, :ensure_all_started, [:nerves_firmware_ssh])
    :ok = :rpc.call(farmbot_node, GenServer, :stop, [Farmbot.Target.SSHConsole])
  end
end
