defmodule Csvm.AST do
  @moduledoc """
  Handy functions for turning various data types into Farbot Celery Script
  Ast nodes.
  """
  alias Csvm.AST
  alias AST.{Heap, Slicer, Unslicer}

  @typedoc "Arguments to a ast node."
  @type args :: map

  @typedoc "Body of a ast node."
  @type body :: [t]

  @typedoc "Kind of a ast node."
  @type kind :: module

  @typedoc "AST node."
  @type t :: %__MODULE__{
          kind: kind,
          args: args,
          body: body,
          comment: binary
        }

  defstruct [:args, :body, :kind, :comment]

  @doc "Decode a base map into CeleryScript AST."
  @spec decode(t() | map) :: t()
  def decode(map_or_list_of_maps)

  def decode(%{__struct__: _} = thing) do
    thing |> Map.from_struct() |> decode
  end

  def decode(%{} = thing) do
    kind = thing["kind"] || thing[:kind] || raise("Bad ast: #{inspect(thing)}")
    args = thing["args"] || thing[:args] || raise("Bad ast: #{inspect(thing)}")
    body = thing["body"] || thing[:body] || []
    comment = thing["comment"] || thing[:comment] || nil

    %__MODULE__{
      kind: String.to_atom(to_string(kind)),
      args: decode_args(args),
      body: decode_body(body),
      comment: comment
    }
  end

  def decode(bad_ast), do: raise("Bad ast: #{inspect(bad_ast)}")

  # You can give a list of nodes.
  @spec decode_body([map]) :: [t()]
  def decode_body(body) when is_list(body) do
    Enum.map(body, fn itm ->
      decode(itm)
    end)
  end

  @spec decode_args(map) :: args
  def decode_args(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, val}, acc ->
      if is_map(val) do
        # if it is a map, it could be another node so decode it too.
        real_val = decode(val)
        Map.put(acc, String.to_atom(to_string(key)), real_val)
      else
        Map.put(acc, String.to_atom(to_string(key)), val)
      end
    end)
  end

  @spec new(atom, map, [map]) :: t()
  def new(kind, args, body) when is_map(args) and is_list(body) do
    %__MODULE__{
      kind: String.to_atom(to_string(kind)),
      args: args,
      body: body
    }
    |> decode()
  end

  @spec slice(AST.t()) :: Heap.t()
  def slice(%AST{} = ast), do: Slicer.run(ast)

  @spec unslice(Heap.t(), Address.t()) :: AST.t()
  def unslice(%Heap{} = heap, %Address{} = addr),
    do: Unslicer.run(heap, addr)
end
