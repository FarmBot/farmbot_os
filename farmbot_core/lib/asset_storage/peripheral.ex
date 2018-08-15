defmodule Farmbot.Asset.Peripheral do
  @moduledoc """
  Peripherals are descriptors for pins/modes.
  """

  alias Farmbot.Asset.Peripheral
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:local_id, :binary_id, autogenerate: true}
  schema "peripherals" do
    field(:id, :integer)
    field(:pin, :integer)
    field(:mode, :integer)
    field(:label, :string)
  end

  @required_fields [:id, :pin, :mode, :label]

  def changeset(%Peripheral{} = peripheral, params \\ %{}) do
    peripheral
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
