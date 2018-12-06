defmodule Mix.Tasks.Farmbot.Firmware.Reload do
  use Mix.Task

  def run([farmbot_node | apps]) do
    # module = Module.concat([Elixir, module])
    # true = Code.ensure_loaded?(module)

    farmbot_node = String.to_atom(farmbot_node)
    {:ok, _} = Node.start(:console)
    Node.set_cookie(:democookie)
    true = Node.connect(farmbot_node)

    Application.load(:farmbot_core)
    Application.load(:farmbot_ext)
    Application.load(:farmbot)

    {:ok, farmbot_core_mods} = :application.get_key(:farmbot_core, :modules)
    {:ok, farmbot_ext_mods} = :application.get_key(:farmbot_ext, :modules)
    {:ok, farmbot_os_mods} = :application.get_key(:farmbot, :modules)

    mods =
      Enum.reduce(apps, [], fn app, acc ->
        app = String.to_atom(app)
        Application.load(app)
        {:ok, more} = :application.get_key(app, :modules)
        acc ++ more
      end)

    for module <- mods ++ farmbot_core_mods ++ farmbot_ext_mods ++ farmbot_os_mods do
      {:ok, [{^farmbot_node, :loaded, ^module}]} = IEx.Helpers.nl([farmbot_node], module)
    end
  end
end
