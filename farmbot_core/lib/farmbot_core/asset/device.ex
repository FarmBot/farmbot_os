defmodule FarmbotCore.Asset.Device do
  @moduledoc """
  The current device. Should only ever be _one_ of these. If not there is a huge
  problem probably higher up the stack.
  """

  use FarmbotCore.Asset.Schema, path: "/api/device"

  schema "devices" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:timezone, :string)
    field(:last_ota, :utc_datetime)
    field(:last_ota_checkup, :utc_datetime)
    field(:ota_hour, :integer)
    field(:mounted_tool_id, :integer)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view device do
    %{
      id: device.id,
      name: device.name,
      timezone: device.timezone,
      last_ota: device.last_ota,
      last_ota_checkup: device.last_ota_checkup,
      ota_hour: device.ota_hour,
      mounted_tool_id: device.mounted_tool_id
    }
  end

  def changeset(device, params \\ %{}) do
    device
    |> cast(params, [:id, 
      :name, 
      :timezone, 
      :last_ota, 
      :last_ota_checkup, 
      :ota_hour,
      :mounted_tool_id,
      :monitor, 
      :created_at, 
      :updated_at
    ])
    |> validate_required([])
  end
end
