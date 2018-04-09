defmodule Farmbot.Asset.Peripheral do
  @moduledoc """
  Peripherals are descriptors for pins/modes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "peripherals" do
    field(:pin, :integer)
    field(:mode, :integer)
    field(:label, :string)
  end

  @required_fields [:id, :pin, :mode, :label]

  def changeset(peripheral, params \\ %{}) do
    peripheral
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
