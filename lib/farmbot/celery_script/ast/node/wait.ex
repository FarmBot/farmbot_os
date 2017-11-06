defmodule Farmbot.CeleryScript.AST.Node.Wait do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:milliseconds]

  def execute(%{milliseconds: ms}, _, env) do
    env = mutate_env(env)
    Process.sleep(ms)
    {:ok, env}
  end
end
