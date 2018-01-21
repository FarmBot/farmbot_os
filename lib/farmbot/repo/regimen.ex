defmodule Farmbot.Repo.Regimen do
  @moduledoc """
  A Regimen is a schedule to run sequences on.
  """

  alias Farmbot.Repo.JSONType

  use Ecto.Schema
  import Ecto.Changeset

  schema "regimens" do
    field(:name, :string)
    field(:regimen_items, JSONType)
  end

  @type item :: %{
    name: String.t,
    time_offset: integer,
    sequence_id: integer
  }

  @type t :: %__MODULE__{
    name: String.t,
    regimen_items: [item]
  }

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name, :regimen_items]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
