defmodule FarmbotOS.Celery.Compiler.Execute do
  alias FarmbotOS.Celery.{
    AST,
    Compiler.Scope
  }

  def execute(%AST{kind: :execute} = execute_ast, previous_scope) do
    if FarmbotOS.BotState.fetch().informational_settings.locked do
      {:error, "Device is locked."}
    else
      do_execute(execute_ast, previous_scope)
    end
  end

  defp do_execute(execute_ast, previous_scope) do
    id = execute_ast.args.sequence_id

    case FarmbotOS.Celery.SysCallGlue.get_sequence(id) do
      %AST{kind: :sequence} = sequence_ast ->
        quote location: :keep do
          # execute_compiler.ex
          sequence = unquote(Macro.escape(sequence_ast))
          cs_scope = unquote(Scope.new(previous_scope, execute_ast.body))
          FarmbotOS.Celery.Compiler.Sequence.sequence(sequence, cs_scope)
        end

      error ->
        error
    end
  end
end
