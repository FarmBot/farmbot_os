defmodule Mix.Tasks.Farmbot.Env do
  @moduledoc false
  use Mix.Task
  def run(_) do
    Mix.shell.info([:green, "Building initial environment for Farmbot OS"])
    Code.eval_file("scripts/generate_makefile.exs", File.cwd!)
  end
end
