defmodule Csvm.AST.Heap do
  @moduledoc """
  A heap-ish data structure required when converting canonical CeleryScript AST
  nodes into the Flat IR form.
  This data structure is useful because it addresses each node in the
  CeleryScript tree via a unique numerical index, rather than using mutable
  references.
  MORE INFO: https://github.com/FarmBot-Labs/Celery-Slicer
  """
  alias Csvm.AST.Heap

  # Constants and key names.

  @link "__"
  @body String.to_atom(@link <> "body")
  @next String.to_atom(@link <> "next")
  @parent String.to_atom(@link <> "parent")
  @kind String.to_atom(@link <> "kind")

  @primary_fields [@parent, @body, @kind, @next]

  @null Address.new(0)
  @nothing %{
    @kind => :nothing,
    @parent => @null,
    @body => @null,
    @next => @null
  }

  def link, do: @link
  def parent, do: @parent
  def body, do: @body
  def next, do: @next
  def kind, do: @kind
  def primary_fields, do: @primary_fields
  def null, do: @null

  defstruct [:entries, :here]

  @type t :: %Heap{
          entries: %{Address.t() => cell()},
          here: here()
        }

  @type here :: Address.t()

  @typedoc "this is actually an atom that starts with __"
  @type link :: atom

  @typedoc "individual heap entry."
  @type cell :: %{
          required(:__kind) => atom,
          required(:__body) => Address.t(),
          required(:__next) => Address.t(),
          required(:__parent) => Address.t()
        }

  @doc "Initialize a new heap."
  @spec new() :: t()
  def new do
    %{struct(Heap) | here: @null, entries: %{@null => @nothing}}
  end

  @doc "Alot a new kind on the heap. Increments `here` on the heap."
  @spec alot(t(), atom) :: t()
  def alot(%Heap{} = heap, kind) do
    here_plus_one = Address.inc(heap.here)

    new_entries = Map.put(heap.entries, here_plus_one, %{@kind => kind})

    %Heap{heap | here: here_plus_one, entries: new_entries}
  end

  @doc "Puts a key/value pair at `here` on the heap."
  @spec put(t(), any, any) :: t()
  def put(%Heap{here: addr} = heap, key, value) do
    put(heap, addr, key, value)
  end

  @doc "Puts a key/value pair at an arbitrary address on the heap."
  @spec put(t(), Address.t(), any, any) :: t()
  def put(%Heap{} = heap, %Address{} = addr, key, value) do
    block = heap[addr] || raise "Bad node address: #{inspect(addr)}"
    new_block = Map.put(block, String.to_atom(to_string(key)), value)
    new_entries = Map.put(heap.entries, addr, new_block)
    %{heap | entries: new_entries}
  end

  @doc "Gets the values of the heap entries."
  @spec values(t()) :: %{Address.t() => cell()}
  def values(%Heap{entries: entries}), do: entries

  # Access behaviour.
  @doc false
  @spec fetch(t, Address.t()) :: {:ok, cell()}
  def fetch(%Heap{} = heap, %Address{} = adr),
    do: Map.fetch(Heap.values(heap), adr)
end
