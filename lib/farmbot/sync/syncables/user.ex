defmodule User do
  @moduledoc """
    A User Object in the DB
  """
  defstruct [id: nil,
   device_id: nil,
   name: nil,
   email: nil,
   created_at: nil,
   updated_at: nil]

 @type t :: %__MODULE__{
   id: integer,
   device_id: integer,
   name: String.t,
   email: String.t,
   created_at: String.t,
   updated_at: String.t}

  @spec create(map) :: t
  def create(%{
    "id" => id,
    "device_id" => device_id,
    "name" => name,
    "email" => email,
    "created_at" => created_at,
    "updated_at" => updated_at})
    when is_integer(id)
     and is_integer(device_id)
     and is_bitstring(name)
     and is_bitstring(email)
     and is_bitstring(created_at)
     and is_bitstring(updated_at)
    do
    %User{
      id: id,
      device_id: device_id,
      name: name,
      email: email,
      created_at: created_at,
      updated_at: updated_at}
  end
  def create(_), do: :error
end
