defmodule Address do
  @moduledoc "Address on the heap."

  defstruct [:value]

  @type value :: integer

  @type t :: %Address{value: value}

  @typedoc "Null address."
  @type null :: %Address{value: 0}

  @doc "New heap address."
  @spec new(integer) :: t()
  def new(num) when is_integer(num), do: %Address{value: num}

  @spec null :: null()
  def null, do: %Address{value: 0}

  @doc "Increment an address."
  @spec inc(t) :: t()
  def inc(%Address{value: num}), do: %Address{value: num + 1}

  @doc "Decrement an address."
  @spec dec(t) :: t()
  def dec(%Address{value: num}), do: %Address{value: num - 1}

  defimpl Inspect, for: Address do
    def inspect(%Address{value: val}, _), do: "#Address<#{val}>"
  end
end
