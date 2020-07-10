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

  # Was not sure where else to put this one.
  # This triggers a hardrefresh of a resource.
  # Useful if you are hitting 409 errors or
  # stale data issues. Internet connectivity is assued.
  def hard_refresh(module) do
    {:ok, changeset} = FarmbotExt.API.get_changeset(module)
    FarmbotCore.Asset.Command.update(module, nil, changeset.changes)
  end
end
