defmodule Farmbot.Asset.Peripheral do
  @moduledoc """
  Peripherals are descriptors for pins/modes.
  """

  use Farmbot.Asset.Schema, path: "/api/peripherals"

  schema "peripherals" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:pin, :integer)
    field(:mode, :integer)
    field(:label, :string)
    timestamps()
  end

  view peripheral do
    %{
      id: peripheral.id,
      pin: peripheral.pin,
      mode: peripheral.mode,
      label: peripheral.label
    }
  end

  def changeset(peripheral, params \\ %{}) do
    peripheral
    |> cast(params, [:id, :pin, :mode, :label, :created_at, :updated_at])
    |> validate_required([])
  end
end
