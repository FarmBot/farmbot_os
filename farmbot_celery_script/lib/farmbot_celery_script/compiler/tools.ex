defmodule Farmbot.CeleryScript.Compiler.Tools do
  @moduledoc false
  # This is an internal DSL tool. Please don't use it for anything else.

  alias Farmbot.CeleryScript.{AST, Compiler, Corpus}

  @doc false
  defmacro __using__([]) do
    quote location: :keep do
      import Compiler.Tools
      @after_compile Compiler.Tools
      Module.register_attribute(__MODULE__, :kinds, accumulate: true)

      @doc "Takes CeleryScript AST and returns Elixir AST"
      def compile_ast(celery_script_ast)
      # Numbers and strings are treated as literals.
      def compile_ast(lit) when is_number(lit), do: lit
      def compile_ast(lit) when is_binary(lit), do: lit
    end
  end

  @doc false
  def __after_compile__(env, _bytecode) do
    kinds = Module.get_attribute(env.module, :kinds)
    not_implemented = Corpus.all_node_names() -- kinds

    for kind <- not_implemented do
      spec = Corpus.node(kind)

      args =
        for %{name: name} <- spec.allowed_args do
          "#{name}: #{name}"
        end

      body = if spec.allowed_body_types == [], do: nil, else: ", _body"

      boilerplate = """
      compile :#{kind}, %{#{Enum.join(args, ", ")}}#{body} do
        quote do
          # Add code here
        end
      end
      """

      IO.warn(
        """
        CeleryScript Node not yet implemented: #{inspect(spec)}
        Boilerplate:
        #{boilerplate}
        """,
        []
      )
    end
  end

  @doc false
  defmacro compile(kind, do: block) when is_atom(kind) do
    quote do
      @kinds unquote(to_string(kind))
      def compile_ast(%AST{kind: unquote(kind)}) do
        unquote(block)
      end
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
