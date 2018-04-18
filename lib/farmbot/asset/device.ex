defmodule Farmbot.Asset.Device do
  @moduledoc """
  The current device. Should only ever be _one_ of these. If not there is a huge
  problem probably higher up the stack.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field(:name, :string)
    field(:timezone, :string)
  end

  @required_fields [:id, :name]

  def changeset(device, params \\ %{}) do
    device
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
