defmodule FarmbotOS.Celery do
  @moduledoc """
  Operations for Farmbot's internal scripting language.
  """

  alias FarmbotOS.Celery.{AST, StepRunner, Scheduler}
  require FarmbotOS.Logger

  @doc "Schedule an AST to execute on a DateTime"
  def schedule(%AST{} = ast, %DateTime{} = at, %{} = data) do
    Scheduler.schedule(ast, at, data)
  end

  @entrypoints [:execute, :sequence, :rpc_request]

  @doc "Execute an AST in place"
  def execute(%AST{kind: k} = ast, tag, caller \\ self())
      when k in @entrypoints do
    StepRunner.begin(caller, tag, ast)
  end

  @doc "Lua VM calls CSVM"
  def execute_from_lua([input_ast], lua) do
    input_ast
    |> FarmbotOS.Lua.Util.lua_to_elixir()
    |> AST.decode()
    |> execute(make_ref(), self())

    receive do
      {:csvm_done, _, :ok} ->
        {[true, nil], lua}

      other ->
        {[false, inspect(other)], lua}
    end
  end
end
