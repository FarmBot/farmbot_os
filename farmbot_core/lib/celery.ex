defmodule FarmbotCore.Celery do
  @moduledoc """
  Operations for Farmbot's internal scripting language.
  """

  alias FarmbotCore.Celery.{AST, StepRunner, Scheduler}
  require FarmbotCore.Logger

  @doc "Schedule an AST to execute on a DateTime"
  def schedule(%AST{} = ast, %DateTime{} = at, %{} = data) do
    Scheduler.schedule(ast, at, data)
  end

  @entrypoints [ :execute, :sequence, :rpc_request ]

  @doc "Execute an AST in place"
  def execute(%AST{kind: k} = ast, tag, caller \\ self()) when k in @entrypoints do
    StepRunner.begin(caller, tag, ast)
  end
end
