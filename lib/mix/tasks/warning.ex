defmodule Mix.Tasks.Farmbot.Warning do
  @moduledoc false
  use Mix.Task
  def run(_), do: Mix.raise("Please export a MIX_TARGET")
end
