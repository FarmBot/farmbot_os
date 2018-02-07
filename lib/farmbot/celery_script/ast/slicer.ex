defmodule Farmbot.CeleryScript.AST.Slicer do
  @moduledoc """
  ORIGINAL IMPLEMENTATION HERE: https://github.com/FarmBot-Labs/Celery-Slicer
  Take a nested ("canonical") representation of a CeleryScript sequence and
  transofrms it to a flat/homogenous intermediate representation which is better
  suited for storage in a relation database.
  """
  alias Farmbot.CeleryScript.AST
  alias AST.Heap
  alias AST.Heap.Address

  def run(%AST{} = canonical) do
    Heap.new()
    |> allocate(canonical, Heap.null())
    |> Map.update(Heap.body(), Heap.null(), fn(x) -> Map.get(x, Heap.body()) end)
    |> Map.update(Heap.next(), Heap.null(), fn(x) -> Map.get(x, Heap.next()) end)
    |> Heap.values()
  end

  def allocate(%Heap{} = heap, %AST{} = node, %Address{} = parent_addr) do
    heap
    |> Heap.alot(node.kind)
    |> Heap.put(Heap.parent(), parent_addr) # puts "here"
    |> iterate_over_body(node)
    |> iterate_over_args(node)
  end

  def iterate_over_args(%Heap{here: %Address{} = parent_addr} = heap, %AST{} = canonical_node) do
    keys = Map.keys(canonical_node.args)
    Enum.reduce(keys, heap, fn(key, %Heap{} = heap) ->
      case canonical_node.args[key] do
        %AST{} = another_node ->
          k = Heap.link <> to_string(key)
          new_heap = heap |> allocate(another_node, parent_addr)
          Heap.put(new_heap, parent_addr, k, new_heap.here)
        val ->
          Heap.put(heap, parent_addr, key, val)
      end
    end)
  end

  def iterate_over_body(%Heap{} = heap, %AST{} = canonical_node) do
    recurse_into_body(heap, canonical_node.body)
  end

  def recurse_into_body(heap, body, index \\ 0)
  def recurse_into_body(%Heap{here: %Address{} = previous_address} = heap, [body_item | rest], index) do
    %Heap{here: my_heap_address} = heap = allocate(heap, body_item, previous_address)
    is_head? = index == 0
    prev_next_key = if is_head?, do: Heap.null(), else: my_heap_address
    prev_body_key = if is_head?, do: my_heap_address, else: Heap.null()
    heap
    |> Heap.put(previous_address, Heap.next(), prev_next_key)
    |> Heap.put(previous_address, Heap.body(), prev_body_key)
    |> recurse_into_body(rest, index + 1)
  end

  def recurse_into_body(heap, [], _), do: heap
end
