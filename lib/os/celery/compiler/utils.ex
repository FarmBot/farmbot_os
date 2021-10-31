defmodule FarmbotOS.Celery.Compiler.Utils do
  alias FarmbotOS.Celery.{
    Compiler,
    AST,
    Compiler.Scope
  }

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
      {_, _, _} = compiled ->
        compile_block(rest, cs_scope, acc ++ [compiled])

      compiled when is_list(compiled) ->
        compile_block(rest, cs_scope, acc ++ compiled)
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

  def add_init_logs(steps, scope, sequence_name) do
    message =
      if Scope.has_key?(scope, "__GROUP__") do
        {:ok, meta} = Scope.fetch!(scope, "__GROUP__")
        "[#{meta.current_index}/#{meta.size}] Starting #{sequence_name}"
      else
        "Starting #{sequence_name}"
      end

    front = [
      quote do
        fn ->
          FarmbotOS.Celery.SysCallGlue.sequence_init_log(unquote(message))
          :ok
        end
      end
    ]

    back = [
      quote do
        fn ->
          FarmbotOS.Celery.SysCallGlue.sequence_complete_log(
            "Completed #{unquote(sequence_name)}"
          )

          :ok
        end
      end
    ]

    front ++ steps ++ back
  end
end
