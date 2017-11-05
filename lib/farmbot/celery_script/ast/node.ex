defmodule Farmbot.CeleryScript.AST.Node do
  @moduledoc "CeleryScript Node."
  alias Farmbot.CeleryScript.AST

  @doc "Decode and validate arguments."
  @callback decode_args(map) :: {:ok, AST.args} | {:error, term}

  @doc "Execute a node"
  @callback execute(AST.args, AST.body, Macro.Env.t) :: {:ok, AST.t} | {:ok, Macro.Env.t} | {:error, Macro.Env.t, term}

  @doc false
  defmacro __after_compile__(env, _) do
    # if we didn't define an execute function; throw a compile error.
    unless function_exported?(env.module, :execute, 3) do
      # err = "#{env.module} does not export a `execute(args, body)` function."
      # raise CompileError, description: err, file: env.file
      quote do end
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      import AST.Node, only: [allow_args: 1]
      @behaviour AST.Node
      @after_compile AST.Node
      require Logger

      # Struct to allow for usage of Elixir Protocols.
      defstruct [:ast]

      @doc false
      def decode_args(args, acc \\ [])

      # The AST Decoder comes in as a map. Change it to a Keyword list
      # before enumeration.
      def decode_args(args, acc) when is_map(args) do
        decode_args(Map.to_list(args), acc)
      end

      def decode_args([{arg_name, val} = arg | rest], acc) do
        # if this is an expected argument, there will be a function
        # defined that points to the argument type implementation.
        # This requires that the Node module has
        # `allow_args [<arg_name>]`
        if {arg_name, 0} in __MODULE__.module_info(:exports) do
          case apply(__MODULE__, arg_name, []).verify(val) do
            # if this argument is valid, continue enumeration.
            {:ok, decoded} -> decode_args(rest, [{arg_name, decoded} | acc])
            {:error, _} = err -> err
          end
        else
          {:error, {:unknown_arg, arg_name}}
        end
      end

      # When we have validated all of the arguments
      # Change it back to a map.
      def decode_args([], acc) do
        {:ok, Map.new(acc)}
      end
    end
  end

  @doc "Allow a list of args."
  defmacro allow_args(args) do
    arg_mod_base = AST.Arg
    args_and_mods = for arg <- args do
      mod = Module.concat(arg_mod_base, Macro.camelize(arg |> to_string))
      {arg, mod}
    end

      for {arg, mod} <- args_and_mods do
        quote do
          # Define this arg, pointing to the module responsible
          # For validating it.
          @doc false
          def unquote(arg)() do
            unless Code.ensure_loaded?(unquote(mod)) do
              raise CompileError,
                description: "Unknown CeleryScript arg: #{unquote(arg)} (#{unquote(mod)})", file: __ENV__.file
            end
            unquote(mod)
          end
        end
      end
  end

end
