defmodule Farmbot.Repo.Sensor do
  @moduledoc """
  Sensors are descriptors for pins/modes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sensors" do
    field(:pin, :integer)
    field(:mode, :integer)
    field(:label, :string)
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :pin, :mode, :label]

  def changeset(peripheral, params \\ %{}) do
    peripheral
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
