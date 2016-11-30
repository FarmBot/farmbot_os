defmodule Toolbay do
  @moduledoc """
    A Toolbay Object in the DB
  """
  defstruct [
    id: nil,
    device_id: nil,
    name: nil]

 @type t :: %__MODULE__{
   id: integer,
   device_id: integer,
   name: String.t}

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(%{
    "id" => id,
    "device_id" => device_id,
    "name" => name})
    when is_integer(id)
     and is_integer(device_id)
     and is_bitstring(name)
    do
      f =
      %__MODULE__{
        id: id,
        device_id: device_id,
        name: name}
       {:ok, f}
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
