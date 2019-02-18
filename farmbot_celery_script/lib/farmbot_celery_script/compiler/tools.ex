defmodule Farmbot.CeleryScript.Compiler.Tools do
  @moduledoc false

  alias Farmbot.CeleryScript.{AST, Compiler, Corpus}

  @doc false
  defmacro __using__([]) do
    quote do
      import Compiler.Tools
      @after_compile Compiler.Tools
      Module.register_attribute(__MODULE__, :kinds, accumulate: true)
    end
  end

  @doc false
  def __after_compile__(env, _bytecode) do
    kinds = Module.get_attribute(env.module, :kinds)
    not_implemented = Corpus.all_node_names() -- kinds

    for kind <- not_implemented do
      IO.warn(
        """
        CeleryScript Node not yet implemented: #{inspect(Corpus.node(kind))}
        """,
        []
      )
    end
  end

  @doc false
  defmacro compile(kind, args_pattern, do: block) when is_atom(kind) do
    quote do
      @kinds unquote(to_string(kind))
      def compile_ast(%AST{kind: unquote(kind), args: unquote(args_pattern)}) do
        unquote(block)
      end
    end
  end

  @doc false
  defmacro compile(kind, args_pattern, body_patterrn, do: block) when is_atom(kind) do
    quote do
      @kinds unquote(to_string(kind))
      def compile_ast(%AST{
            kind: unquote(kind),
            args: unquote(args_pattern),
            body: unquote(body_patterrn)
          }) do
        unquote(block)
      end
    end
  end
end
