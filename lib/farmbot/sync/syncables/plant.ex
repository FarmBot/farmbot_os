defmodule Plant do
  @moduledoc """
    Dont worry about this.
  """
  defstruct []
  @type t :: %__MODULE__{}
  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(map)
  when is_map(map) do
    {:ok, %Plant{}}
  end
  def create(_), do: {__MODULE__, :malformed}
  
  @spec create!(map) :: t
  def create!(thing) do
    case create(thing) do
      {:ok, success} -> success
      {__MODULE__, :malformed} -> raise "Malformed #{__MODULE__} Object"
    end
  end
end
