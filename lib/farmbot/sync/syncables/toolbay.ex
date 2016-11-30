defmodule Toolbay do
  @moduledoc """
    A Toolbay Object in the DB
  """
  defstruct [id: nil,
   device_id: nil,
   name: nil,
   created_at: nil,
   updated_at: nil]

 @type t :: %__MODULE__{
   id: integer,
   device_id: integer,
   name: String.t,
   created_at: String.t,
   updated_at: String.t}

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(%{
    "id" => id,
    "device_id" => device_id,
    "name" => name,
    "created_at" => created_at,
    "updated_at" => updated_at})
    when is_integer(id)
     and is_integer(device_id)
     and is_bitstring(name)
     and is_bitstring(created_at)
     and is_bitstring(updated_at)
    do
      f =
      %__MODULE__{
        id: id,
        device_id: device_id,
        name: name,
        created_at: created_at,
        updated_at: updated_at}
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
