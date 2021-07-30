defmodule FarmbotCeleryScript.Compiler.Utils do
  alias FarmbotCeleryScript.{Compiler, AST}
  @doc """
  Recursively compiles a list or single Celery AST into an Elixir `__block__`
  """
  def compile_block(ast, cs_scope) do
    compile_block(ast, cs_scope, [])
  end

  def compile_block(%AST{} = ast, cs_scope, _) do
    case Compiler.compile(ast, cs_scope) do
      {_, _, _} = compiled -> {:__block__, [], [compiled]}
      compiled when is_list(compiled) -> {:__block__, [], compiled}
    end
  end

  def compile_block([ast | rest], cs_scope, acc) do
    case Compiler.compile(ast, cs_scope) do
      {_, _, _} = compiled -> compile_block(rest, cs_scope, acc ++ [compiled])
      compiled when is_list(compiled) -> compile_block(rest, cs_scope, acc ++ compiled)
    end
  end

  def compile_block([], _cs_scope, acc), do: {:__block__, [], acc}

  def decompose_block_to_steps({:__block__, _, steps} = _orig) do
    Enum.map(steps, fn step ->
      quote location: :keep do
        fn -> unquote(step) end
      end
    end)
  end

  def add_sequence_init_and_complete_logs(steps, sequence_name)
      when is_binary(sequence_name) do
    # This looks really weird because of the logs before and
    # after the compiled steps
    List.flatten([
      quote location: :keep do
        fn ->
          FarmbotCeleryScript.SysCalls.sequence_init_log(
            "Starting #{unquote(sequence_name)}"
          )
        end
      end,
      steps,
      quote  location: :keep do
        fn ->
          FarmbotCeleryScript.SysCalls.sequence_complete_log(
            "Completed #{unquote(sequence_name)}"
          )
        end
      end
    ])
  end

  def add_sequence_init_and_complete_logs(steps, _) do
    steps
  end

  def add_sequence_init_and_complete_logs_ittr(steps, sequence_name)
      when is_binary(sequence_name) do
    # This looks really weird because of the logs before and
    # after the compiled steps
    List.flatten([
      quote location: :keep do
        fn _ ->
          [
            fn ->
              FarmbotCeleryScript.SysCalls.sequence_init_log(
                "Starting #{unquote(sequence_name)}"
              )
            end
          ]
        end
      end,
      steps,
      quote location: :keep do
        fn _ ->
          [
            fn ->
              FarmbotCeleryScript.SysCalls.sequence_complete_log(
                "Completed #{unquote(sequence_name)}"
              )
            end
          ]
        end
      end
    ])
  end

  def add_sequence_init_and_complete_logs_ittr(steps, _) do
    steps
  end
end
