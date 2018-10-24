defmodule Farmbot.Asset.PinBinding do
  @moduledoc """
  When a pin binding is triggered a sequence fires.
  """
  use Farmbot.Asset.Schema, path: "/api/pin_bindings"

  schema "pin_bindings" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:pin_num, :integer)
    field(:sequence_id, :integer)
    field(:special_action, :string)
    timestamps()
  end

  view pin_binding do
    %{
      id: pin_binding.id,
      pin_num: pin_binding.pin_num,
      sequence_id: pin_binding.sequence_id,
      special_action: pin_binding.special_action
    }
  end

  def changeset(pin_binding, params \\ %{}) do
    pin_binding
    |> cast(params, [:id, :pin_num, :sequence_id, :special_action, :created_at, :updated_at])
    |> validate_required([])
    |> validate_pin_num()
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
