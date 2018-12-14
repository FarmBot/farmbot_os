defmodule Mix.Tasks.Farmbot.Firmware.EnvChange do
  use Mix.Task

  def run([node_name]) do
    node_name = connect!(node_name)
    files = :rpc.call(node_name, Path, :wildcard, ["/root/*-dev.sqlite3"])
    :rpc.call(node_name, Enum, :each, [files, fn(filename) ->
      new_filename = String.replace(filename, "dev", "prod")
      File.cp!(filename, new_filename)
    end])
  end

  defp connect!(farmbot_node) do
    farmbot_node = String.to_atom(farmbot_node)
    {:ok, _} = Node.start(:reloader, :shortnames)
    Node.set_cookie(:democookie)
    true = Node.connect(farmbot_node)
    Application.load(:farmbot)
    farmbot_node
  end
end
