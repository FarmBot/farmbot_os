defmodule Tool do
  @moduledoc """
    A #{__MODULE__} Object in the DB
  """
  @enforce_keys [:id, :slot_id, :name]
  defstruct @enforce_keys
  @type t :: %__MODULE__{
    id: integer,
    slot_id: integer,
    name: String.t
  }
  @type json_map :: map
  @spec create(json_map) :: {:ok, t} | {atom, :malformed}
  @doc """
    Creates a #{__MODULE__} Object.
    returns {:ok, %#{__MODULE__}} or {#{__MODULE__}, :malformed}
  """
  def create(
  %{"id" => id,
    "slot_id" => slot_id,
    "name" => name})
  do
    f = %__MODULE__{
      id: id,
      slot_id: slot_id,
      name: name
    }
    {:ok, f}
  end
  def create(_), do: {__MODULE__, :malformed}

  @spec create!(map) :: t
  @doc """
    Same as create\1 but raises an exception if it fails.
  """
  def create!(thing) do
    case create(thing) do
      {:ok, success} -> success
      {__MODULE__, :malformed} -> raise "Malformed #{__MODULE__} Object"
    end
  end
end
