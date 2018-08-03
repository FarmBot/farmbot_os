defmodule Csvm.AST.Unslicer do
  @moduledoc """
  Turn an AST Heap back into an AST.
  """
  alias Csvm.AST
  alias Csvm.AST.Heap

  @link Heap.link()
  @parent Heap.parent()
  @body Heap.body()
  @next Heap.next()
  @kind Heap.kind()

  @typedoc "Ast with String Keys"
  @type pre_ast :: map

  @doc "Unslices a Heap struct back to cannonical celeryscript."
  @spec run(Heap.t(), Address.t()) :: AST.t()
  def run(%Heap{} = heap, %Address{} = addr) do
    heap
    |> unslice(addr)
    |> Csvm.AST.decode()
  end

  @spec unslice(Heap.t(), Address.t()) :: pre_ast
  defp unslice(heap, addr) do
    here_cell = heap[addr] || raise "No cell at address: #{inspect(addr)}"

    Enum.reduce(here_cell, %{"args" => %{}}, fn {key, value}, acc ->
      if is_link?(key) do
        do_unslice(heap, key, value, acc)
      else
        %{acc | "args" => Map.put(acc["args"], to_string(key), value)}
      end
    end)
  end

  @spec do_unslice(Heap.t(), Heap.link(), any, acc :: map) :: acc :: map
  defp do_unslice(_heap, @parent, _value, acc), do: acc
  defp do_unslice(_heap, @next, _value, acc), do: acc

  defp do_unslice(_heap, @kind, value, acc),
    do: Map.put(acc, "kind", to_string(value))

  defp do_unslice(heap, @body, value, acc) do
    if heap[value][@kind] == :nothing do
      acc
    else
      next_addr = value
      n = heap[next_addr]
      body = reduce_body(n, next_addr, heap, [])
      Map.put(acc, "body", body)
    end
  end

  defp do_unslice(heap, key, value, acc) do
    key = String.replace(to_string(key), @link, "")
    args = Map.put(acc["args"], key, unslice(heap, value))
    %{acc | "args" => args}
  end

  @spec reduce_body(Heap.cell(), Address.t(), Heap.t(), [pre_ast]) :: [pre_ast]
  defp reduce_body(%{__kind: :nothing}, _next_addr, _heap, acc),
    do: acc

  defp reduce_body(%{} = cell, %Address{} = next_addr, heap, acc) do
    item = unslice(heap, next_addr)
    new_acc = acc ++ [item]
    next_addr = cell[@next]
    next_cell = heap[next_addr]
    reduce_body(next_cell, next_addr, heap, new_acc)
  end

  @spec is_link?(atom) :: boolean()
  defp is_link?(key) do
    String.starts_with?(to_string(key), @link)
  end
end
