defmodule Mix.Tasks.Farmbot.Discover do
  @moduledoc """
  Discover development Farmbot's on the network.
  """

  use Mix.Task

  def run([]) do
    nodes = Nerves.SSDPClient.discover
    fb_nodes = Enum.reduce(nodes, [], fn({usn, device}, acc) ->
      if match?("farmbot:" <> _rest, usn) do
        [device | acc]
      else
        acc
      end
    end)
    # IO.inspect fb_nodes
    node_names = Enum.map(fb_nodes, fn(%{st: "nerves:farmbot:" <> nn} = device) -> "#{nn} (#{device.host})" end)
    IO.puts(Enum.join(Enum.uniq(node_names), ", "))
    fb_nodes
  end
end
