defmodule Pointer do
  @moduledoc "Generic pointer that takes two values."
  defstruct [:heap_address, :page_address]

  @type t :: %__MODULE__{
          heap_address: Address.t(),
          page_address: Address.t()
        }

  @type null_pointer :: %__MODULE__{
          heap_address: Address.null(),
          page_address: Address.t()
        }

  @doc """
  Returns a new Pointer.
  """
  @spec new(Address.t(), Address.t()) :: Pointer.t()
  def new(%Address{} = page_address, %Address{} = heap_address) do
    %Pointer{
      heap_address: heap_address,
      page_address: page_address
    }
  end

  @doc "Returns a null pointer based on a passed in zero page address."
  @spec null(Address.t()) :: Pointer.null_pointer()
  def null(%Address{} = zero_page) do
    %Pointer{
      heap_address: Address.new(0),
      page_address: zero_page
    }
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%Pointer{heap_address: ha, page_address: pa}, _),
      do: "#Pointer<#{pa.value}, #{ha.value}>"
  end
end
