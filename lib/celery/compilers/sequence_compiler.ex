defmodule FarmbotOS.Celery.Compiler.Sequence do
  alias FarmbotOS.Celery.Compiler.{Scope, Utils}

  def sequence(ast, cs_scope) do
    sequence_header = ast.args.locals.body
    # Apply defaults declared by sequence
    cs_scope
    |> Scope.apply_defaults(sequence_header)
    # Apply declarations within sequence (if any)
    |> Scope.apply_declarations(sequence_header)
    |> Scope.expand()
    |> compile_expanded_sequences(ast)
  end

  defp compile_expanded_sequences(cs_scope_array, ast) do
    Enum.map(cs_scope_array, fn cs_scope ->
      steps =
        ast.body
        |> Utils.compile_block(cs_scope)
        |> Utils.decompose_block_to_steps()
        |> Utils.add_init_logs(
          cs_scope,
          Map.get(ast.args, :sequence_name, "sequence")
        )

      quote location: :keep do
        fn ->
          cs_scope = unquote(cs_scope)
          _ = inspect(cs_scope)
          # Unquote the remaining sequence steps.
          unquote(steps)
        end
      end
    end)
  end
end
