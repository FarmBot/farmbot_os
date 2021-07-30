defmodule FarmbotCeleryScript.Compiler.Execute do
  alias FarmbotCeleryScript.{
    AST,
    # Compiler,
    Compiler.Scope
  }

  def execute(%AST{kind: :execute} = execute_ast, previous_scope) do
    id = execute_ast.args.sequence_id
    case FarmbotCeleryScript.SysCalls.get_sequence(id) do
      %AST{kind: :sequence} = sequence_ast ->
        quote location: :keep do
          # execute_compiler.ex
          sequence = unquote(sequence_ast)
          cs_scope = unquote(Scope.new(previous_scope, execute_ast.body))
          FarmbotCeleryScript.Compiler.Sequence.sequence(sequence, cs_scope)
        end
      error ->
        error
    end
  end
end
