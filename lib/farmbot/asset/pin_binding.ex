defmodule Farmbot.Asset.PinBinding do
  @moduledoc """
  When a pin binding is triggered a sequence fires.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "pin_bindings" do
    field(:pin_num, :integer)
    field(:sequence_id, :integer)
  end

  @required_fields [:id, :pin_num, :sequence_id]

  def changeset(pin_binding, params \\ %{}) do
    pin_binding
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
