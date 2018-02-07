defmodule Farmbot.CeleryScript.AST.Heap do
  @moduledoc """
  A heap-ish data structure required when converting canonical CeleryScript AST
  nodes into the Flat IR form.
  This data structure is useful because it addresses each node in the
  CeleryScript tree via a unique numerical index, rather than using mutable
  references.
  MORE INFO: https://github.com/FarmBot-Labs/Celery-Slicer
  """
  alias Farmbot.CeleryScript.AST
  alias AST.Heap

  defmodule Address do
    @moduledoc "Address on the heap."

    defstruct [:value]

    @doc "New heap address."
    def new(num) when is_integer(num) do
      %__MODULE__{value: num}
    end

    @doc "Increment an address."
    def inc(%__MODULE__{value: num}) do
      %__MODULE__{value: num + 1}
    end

    @doc "Decrement an address."
    def dec(%__MODULE__{value: num}) do
      %__MODULE__{value: num - 1}
    end

    defimpl Inspect, for: __MODULE__ do
      def inspect(%{value: val}, _) do
        "Address(#{val})"
      end
    end
  end

  @link   "__"
  @parent String.to_atom(@link <> "parent" <> @link)
  @body   String.to_atom(@link <> "body"   <> @link)
  @next   String.to_atom(@link <> "next"   <> @link)
  @kind   :__kind__

  @primary_fields [@parent, @body, @kind, @next]

  @null Address.new(0)
  @nothing %{
    @kind => AST.Node.Nothing,
    @parent => @null,
    @body => @null,
    @next => @null
  }

  defstruct [:entries, :here]

  def new do
    %{struct(Heap) | here: @null, entries: %{@null => @nothing}}
  end

  def alot(%Heap{} = heap, kind) do
    here_plus_one = Address.inc(heap.here)
    new_entries = Map.put(heap.entries, here_plus_one, %{@kind => kind})
    %{heap | here: here_plus_one, entries: new_entries}
  end

  def put(%Heap{here: addr} = heap, key, value) do
    put(heap, addr, key, value)
  end

  def put(%Heap{} = heap, %Address{} = addr, key, value) do
    block       = heap[addr] || raise "Bad node address: #{inspect addr}"
    new_block   = Map.put(block, String.to_atom(to_string(key)), value)
    new_entries = Map.put(heap.entries, addr, new_block)
    %{heap | entries: new_entries}
  end

  @doc "Gets the values of the heap entries."
  def values(%Heap{entries: entries}), do: Enum.map(entries, &elem(&1, 1))

  @doc false
  def fetch(%Heap{} = heap, %Address{} = addr), do: Map.fetch(heap.entries, addr)

  def link,           do: @link
  def parent,         do: @parent
  def body,           do: @body
  def next,           do: @next
  def kind,           do: @kind
  def primary_fields, do: @primary_fields
  def null,           do: @null

  @compile inline: [
    link: 0, parent: 0, body: 0, next: 0, kind: 0, primary_fields: 0, null: 0
  ]
end
