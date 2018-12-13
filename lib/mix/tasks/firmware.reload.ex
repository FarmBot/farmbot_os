defmodule Mix.Tasks.Farmbot.Firmware.Reload do
  use Mix.Task

  defp connect(farmbot_node) do
    farmbot_node = String.to_atom(farmbot_node)
    {:ok, _} = Node.start(:reloader, :shortnames)
    Node.set_cookie(:democookie)
    true = Node.connect(farmbot_node)
    Application.load(:farmbot)
    farmbot_node
  end

  def run([farmbot_node, module]) do
    farmbot_node = connect(farmbot_node)
    module = Module.concat(["Elixir", module])
    true = Code.ensure_loaded?(module)
    {:ok, [{^farmbot_node, :loaded, ^module}]} = IEx.Helpers.nl([farmbot_node], module)
  end

  def run([farmbot_node | apps]) do
    farmbot_node = connect(farmbot_node)
    {:ok, farmbot_mods} = :application.get_key(:farmbot, :modules)
    mods =
      Enum.reduce(apps, [], fn app, acc ->
        app = String.to_atom(app)
        Application.load(app)
        {:ok, more} = :application.get_key(app, :modules)
        acc ++ more
      end)

    for module <- mods ++ farmbot_mods do
      {:ok, [{^farmbot_node, :loaded, ^module}]} = IEx.Helpers.nl([farmbot_node], module)
    end
  end
end
