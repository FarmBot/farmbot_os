defmodule Regimen do
  @moduledoc """
    Regimen Object
  """
  defstruct [id: nil, color: nil, name: nil, device_id: nil]
  @type t :: %__MODULE__{
   id: integer,
   device_id: integer,
   color: String.t,
   name: String.t}

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(%{
    "id" => id,
    "device_id" => device_id,
    "color" => color,
    "name" => name})
    when is_integer(id)
     and is_integer(device_id)
     and is_bitstring(color)
     and is_bitstring(name)
    do
      f =
      %Regimen{id: id,
               device_id: device_id,
               color: color,
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
