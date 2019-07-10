defmodule FarmbotCeleryScript do
  @moduledoc """
  Operations for Farmbot's internal scripting language.
  """

  alias FarmbotCeleryScript.{AST, Scheduler, StepRunner}

  @doc "Schedule an AST to execute on a DateTime"
  def schedule(%AST{} = ast, %DateTime{} = at, %{} = data) do
    Scheduler.schedule(ast, at, data)
  end

  @doc "Execute an AST in place"
  def execute(%AST{} = ast, tag) do
    StepRunner.step(self(), tag, ast)
  end
end
