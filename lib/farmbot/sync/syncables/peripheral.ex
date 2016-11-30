defmodule Peripheral do
  @moduledoc """
    Peripheral Object
  """
  defstruct [
    id: nil,
    device_id: nil,
    pin: nil,
    mode: nil,
    label: nil,
    created_at: nil,
    updated_at: nil]
 @type t :: %__MODULE__{
   id: integer,
   device_id: integer,
   pin: integer,
   mode: integer,
   label: String.t,
   created_at: String.t,
   updated_at: String.t}

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(%{
    "id" => id,
    "device_id" => device_id,
    "pin" => pin,
    "mode" => mode,
    "label" => label,
    "created_at" => created_at,
    "updated_at" => updated_at})
  do
    f =
    %Peripheral{
      id: id,
      device_id: device_id,
      pin: pin,
      mode: mode,
      label: label,
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
