defmodule Farmbot.CeleryScript.AST do
  @moduledoc """
  Handy functions for turning various data types into Farbot Celery Script
  Ast nodes.
  """

  defmodule Arg do
    @moduledoc "CeleryScript Argument."

    @doc "Verify this arg."
    @callback verify(any) :: {:ok, any} | {:error, term}
  end

  defmodule Node do
    @moduledoc "CeleryScript Node."

    @doc "Decode and validate arguments."
    @callback decode_args(map) :: {:ok, map} | {:error, term}

    @doc false
    defmacro __using__(_) do
      quote do
        import Farmbot.CeleryScript.AST.Node
        @behaviour Farmbot.CeleryScript.AST.Node

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
      arg_mod_base = Farmbot.CeleryScript.AST.Arg
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

  # AST struct.
  defstruct [:kind, :args, :body, :comment]

  @doc "Try to decode anything into an AST struct."
  def decode(arg1)

  def decode(binary) when is_binary(binary) do
    case Poison.decode(binary, keys: :atoms) do
      {:ok, string_map} -> decode(string_map)
      {:error, _}       -> {:error, :unknown_binary}
    end
  end

  def decode(list) when is_list(list), do: decode_body(list)

  def decode(%{kind: kind, args: args} = map) do
    case kind_to_mod(kind) do
      nil -> {:error, {:unknown_kind, kind}}
      mod when is_atom(mod) ->
        case decode_body(map[:body] || []) do
          {:ok, body} ->
            IO.puts mod
            case mod.decode_args(args) do
              {:ok, decoded} ->
                opts = [kind: mod,
                        args: decoded,
                        body: body,
                        comment: map[:comment]]
                val = struct(__MODULE__, opts)
                {:ok, val}
              {:error, _} = err -> err
            end
          {:error, _} = err -> err
        end
    end
  end

  # decode a list of ast nodes.
  defp decode_body(body, acc \\ [])
  defp decode_body([node | rest], acc) do
    case decode(node) do
      {:ok, re} -> decode_body(rest, [re | acc])
      {:error, _} = err -> err
    end
  end

  defp decode_body([], acc), do: {:ok, Enum.reverse(acc)}

  @doc "Lookup a module by it's kind."
  def kind_to_mod(kind) when is_binary(kind) do
    mod = [__MODULE__, "Node", Macro.camelize(kind)] |> Module.concat()
    case Code.ensure_loaded?(mod) do
      false -> nil
      true  -> mod
    end
  end

end
