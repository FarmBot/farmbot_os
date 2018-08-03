defmodule Csvm.AST.Slicer do
  @moduledoc """
  ORIGINAL IMPLEMENTATION HERE: https://github.com/FarmBot-Labs/Celery-Slicer
  Take a nested ("canonical") representation of a CeleryScript sequence and
  transofrms it to a flat/homogenous intermediate representation which is better
  suited for storage in a relation database.
  """
  alias Csvm.AST
  alias AST.Heap

  @doc "Sice the canonical AST format into a AST Heap."
  @spec run(AST.t()) :: Heap.t()
  def run(canonical)

  def run(%AST{} = canonical) do
    Heap.new()
    |> allocate(canonical, Heap.null())
    |> elem(1)
    |> Map.update(:entries, :error, fn entries ->
      Map.new(entries, fn {key, entry} ->
        entry =
          Map.put(
            entry,
            Heap.body(),
            Map.get(entry, Heap.body(), Heap.null())
          )

        entry =
          Map.put(
            entry,
            Heap.next(),
            Map.get(entry, Heap.next(), Heap.null())
          )

        {key, entry}
      end)
    end)
  end

  @doc false
  @spec allocate(Heap.t(), AST.t(), Address.t()) :: {Heap.here(), Heap.t()}
  def allocate(%Heap{} = heap, %AST{} = ast, %Address{} = parent_addr) do
    %Heap{here: addr} = heap = Heap.alot(heap, ast.kind)

    new_heap =
      Heap.put(heap, Heap.parent(), parent_addr)
      |> iterate_over_body(ast, addr)
      |> iterate_over_args(ast, addr)

    {addr, new_heap}
  end

  @spec iterate_over_args(Heap.t(), AST.t(), Address.t()) :: Heap.t()
  defp iterate_over_args(
         %Heap{} = heap,
         %AST{} = canonical_node,
         parent_addr
       ) do
    keys = Map.keys(canonical_node.args)

    Enum.reduce(keys, heap, fn key, %Heap{} = heap ->
      case canonical_node.args[key] do
        %AST{} = another_node ->
          k = Heap.link() <> to_string(key)
          {addr, new_heap} = allocate(heap, another_node, parent_addr)
          Heap.put(new_heap, parent_addr, k, addr)

        val ->
          Heap.put(heap, parent_addr, key, val)
      end
    end)
  end

  @spec iterate_over_body(Heap.t(), AST.t(), Address.t()) :: Heap.t()
  defp iterate_over_body(
         %Heap{} = heap,
         %AST{} = canonical_node,
         parent_addr
       ) do
    recurse_into_body(heap, canonical_node.body, parent_addr)
  end

  @spec recurse_into_body(Heap.t(), [AST.t()], Address.t(), integer) :: Heap.t()
  defp recurse_into_body(heap, body, parent_addr, index \\ 0)

  defp recurse_into_body(
         %Heap{} = heap,
         [body_item | rest],
         prev_addr,
         0
       ) do
    {my_heap_address, %Heap{} = new_heap} =
      heap
      |> Heap.put(prev_addr, Heap.body(), Address.inc(prev_addr))
      |> allocate(body_item, prev_addr)

    new_heap
    |> Heap.put(prev_addr, Heap.next(), Heap.null())
    |> recurse_into_body(rest, my_heap_address, 1)
  end

  defp recurse_into_body(
         %Heap{} = heap,
         [body_item | rest],
         prev_addr,
         index
       ) do
    {my_heap_address, %Heap{} = heap} = allocate(heap, body_item, prev_addr)

    new_heap = Heap.put(heap, prev_addr, Heap.next(), my_heap_address)
    recurse_into_body(new_heap, rest, my_heap_address, index + 1)
  end

  defp recurse_into_body(%Heap{} = heap, [], _, _), do: heap
end
