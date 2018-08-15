defmodule Farmbot.Asset.Device do
  @moduledoc """
  The current device. Should only ever be _one_ of these. If not there is a huge
  problem probably higher up the stack.
  """

  alias Farmbot.Asset.Device
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:local_id, :binary_id, autogenerate: true}
  schema "devices" do
    field(:id, :integer)
    field(:name, :string)
    field(:timezone, :string)
  end

  @required_fields [:id, :name]

  def changeset(%Device{} = device, params \\ %{}) do
    device
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
