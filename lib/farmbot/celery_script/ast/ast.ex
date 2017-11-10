defmodule Farmbot.CeleryScript.AST do
  @moduledoc """
  Handy functions for turning various data types into Farbot Celery Script
  Ast nodes.
  """

  @typedoc "Arguments to a Node."
  @type args :: map

  @typedoc "Body of a Node."
  @type body :: [t]

  @typedoc "Kind of a Node."
  @type kind :: module

  @typedoc "AST node."
  @type t :: %__MODULE__{
    kind: kind,
    args: args,
    body: body,
    comment: binary
  }

  # AST struct.
  defstruct [:kind, :args, :body, :comment]

  @doc "Encode a AST back to a map."
  def encode(%__MODULE__{kind: mod, args: args, body: body, comment: comment}) do
    case mod.encode_args(args) do
      {:ok, encoded_args} ->
        case encode_body(body) do
          {:ok, encoded_body} ->
            {:ok, %{kind: mod_to_kind(mod), args: encoded_args, body: encoded_body, comment: comment}}
          {:error, _} = err -> err
        end
      {:error, _} = err -> err
    end
  end

  @doc "Encode a list of asts."
  def encode_body(body, acc \\ [])

  def encode_body([ast | rest], acc) do
    case encode(ast) do
      {:ok, encoded} -> encode_body(rest, [encoded | acc])
      {:error, _} = err -> err
    end
  end

  def encode_body([], acc), do: {:ok, Enum.reverse(acc)}

  @doc "Try to decode anything into an AST struct."
  def decode(arg1)

  def decode(binary) when is_binary(binary) do
    case Poison.decode(binary, keys: :atoms) do
      {:ok, map}  -> decode(map)
      {:error, :invalid, _} -> {:error, :unknown_binary}
      {:error, _} -> {:error, :unknown_binary}
    end
  end

  def decode(list) when is_list(list), do: decode_body(list)

  def decode(%{__struct__: _} = herp) do
    Map.from_struct(herp) |> decode()
  end

  def decode(%{"kind" => kind, "args" => str_args} = str_map) do
    args = Map.new(str_args, &str_to_atom(&1))
    case decode(str_map["body"] || []) do
      {:ok, body} ->
        IO.puts ""
        %{kind: kind,
          args: args,
          body: body,
          comment: str_map["comment"]}
        |> decode()
      {:error, _} = err -> err
    end
  end

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
              {:error, reason} -> {:error, {kind, reason}}
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

  def kind_to_mod(module) when is_atom(module) do
    module
  end

  @doc "Change a module back to a kind."
  def mod_to_kind(module) when is_atom(module) do
    Module.split(module) |> List.last() |> Macro.underscore()
  end

  defp str_to_atom({key, value}) do
    k = if is_atom(key), do: key, else: String.to_atom(key)
    cond do
      is_map(value)  -> {k, Map.new(value, &str_to_atom(&1))}
      is_list(value) -> {k, Enum.map(value, fn(sub_str_map) -> Map.new(sub_str_map, &str_to_atom(&1)) end)}
      is_binary(value) -> {k, value}
      is_atom(value) -> {k, value}
      is_number(value) -> {k, value}
    end
  end

end
