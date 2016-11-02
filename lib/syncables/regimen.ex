defmodule Regimen do
  defstruct [id: nil, color: nil, name: nil, device_id: nil]
  @type t :: %__MODULE__{
   id: integer,
   device_id: integer,
   color: String.t,
   name: String.t }

  @spec create(map) :: t
  def create(%{
    "id" => id,
    "device_id" => device_id,
    "color" => color,
    "name" => name })
    when is_integer(id)
     and is_integer(device_id)
     and is_bitstring(color)
     and is_bitstring(name)
    do
    %Regimen{ id: id,
              device_id: device_id,
              color: color,
              name: name}
  end
end
