defmodule Farmbot.Asset.Sensor do
  @moduledoc """
  Sensors are descriptors for pins/modes.
  """

  alias Farmbot.Asset.Sensor 
  use Ecto.Schema
  import Ecto.Changeset

  schema "sensors" do
    field(:pin, :integer)
    field(:mode, :integer)
    field(:label, :string)
  end

  @required_fields [:id, :pin, :mode, :label]

  def changeset(%Sensor{} = sensor, params \\ %{}) do
    %Sensor{} = sensor
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
