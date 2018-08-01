defmodule CircularList do
  defstruct current_index: 0, items: %{}, autoinc: -1

  @opaque index :: number
  @type data :: any

  @type t :: %CircularList{
          current_index: index,
          autoinc: index,
          items: %{optional(index) => data}
        }

  @spec new :: %CircularList{
          current_index: 0,
          autoinc: -1,
          items: %{}
        }
  def new do
    %CircularList{}
  end

  @spec get_index(t) :: index
  def get_index(this) do
    this.current_index
  end

  @spec current(t) :: data()
  def current(this) do
    at(this, get_index(this))
  end

  @spec at(t(), index) :: data()
  def at(this, index) do
    this.items[index]
  end

  @spec is_empty?(t()) :: boolean()
  def is_empty?(%{items: items}) when map_size(items) == 0, do: true
  def is_empty?(_this), do: false

  @spec reduce(t(), (index, data -> data)) :: t()
  def reduce(this, fun) do
    results = Enum.reduce(this.items, %{}, fun)

    %{this | items: results}
    |> rotate()
  end

  @spec update_current(t, (data -> data)) :: t
  def update_current(this, fun) do
    index = get_index(this)
    current_value = at(this, index)

    if current_value do
      result = fun.(current_value)
      %{this | items: Map.put(this.items, index, result)}
    else
      fun.(:noop)
      this
    end
  end

  @spec rotate(t) :: t
  def rotate(this) do
    current = this.current_index
    keys = Enum.sort(Map.keys(this.items))
    # Grab first where index > this.current_index, or keys.first
    next_key = Enum.find(keys, List.first(keys), fn key -> key > current end)
    %CircularList{this | current_index: next_key}
  end

  @spec push(t, data) :: t
  def push(this, item) do
    # Bump autoinc
    next_autoinc = this.autoinc + 1
    next_items = Map.put(this.items, next_autoinc, item)
    # Add the item
    %CircularList{this | autoinc: next_autoinc, items: next_items}
  end

  @spec remove(t, index) :: t
  def remove(this, index) do
    if index in Map.keys(this.items) do
      this
      |> rotate()
      |> Map.update(:items, %{}, fn old_items ->
        Map.delete(old_items, index)
      end)
    else
      this
    end
  end
end
