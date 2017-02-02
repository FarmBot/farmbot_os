defmodule Mix.Tasks.Farmbot.Warning do
  use Mix.Task
  def run(_), do: Mix.raise("Please export a MIX_TARGET")
end
