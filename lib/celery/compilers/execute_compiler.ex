defmodule FarmbotCore.Celery.Compiler.Execute do
  alias FarmbotCore.Celery.{
    AST,
    Compiler.Scope
  }

  def execute(%AST{kind: :execute} = execute_ast, previous_scope) do
    if FarmbotCore.BotState.fetch().informational_settings.locked do
      {:error, "Device is locked."}
    else
      do_execute(execute_ast, previous_scope)
    end
  end

  defp do_execute(execute_ast, previous_scope) do
    id = execute_ast.args.sequence_id

    case FarmbotCore.Celery.SysCallGlue.get_sequence(id) do
      %AST{kind: :sequence} = sequence_ast ->
        quote location: :keep do
          # execute_compiler.ex
          sequence = unquote(sequence_ast)
          cs_scope = unquote(Scope.new(previous_scope, execute_ast.body))
          FarmbotCore.Celery.Compiler.Sequence.sequence(sequence, cs_scope)
        end

      error ->
        error
    end
  end
end
