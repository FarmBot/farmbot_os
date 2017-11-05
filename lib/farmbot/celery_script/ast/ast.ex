defmodule Farmbot.CeleryScript.AST do
  @moduledoc """
  Handy functions for turning various data types into Farbot Celery Script
  Ast nodes.
  """

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
