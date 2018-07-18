defmodule Farmbot.Asset.PinBinding do
  @moduledoc """
  When a pin binding is triggered a sequence fires.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "pin_bindings" do
    field(:pin_num, :integer)
    field(:sequence_id, :integer)
    field(:special_action, :string)
  end

  @required_fields [:id, :pin_num]

  def changeset(pin_binding, params \\ %{}) do
    pin_binding
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_pin_num()
    |> unique_constraint(:id)
    |> unique_constraint(:pin_num)
  end

  def validate_pin_num(changeset) do
    if get_field(changeset, :pin_num, -1) in [17, 23, 27, 06, 21, 24, 25, 12, 13] do
      add_error(changeset, :pin_num, "in use")
    else
      changeset
    end
  end
end
