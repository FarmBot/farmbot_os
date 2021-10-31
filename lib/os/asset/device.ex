defmodule FarmbotOS.Asset.Device do
  @moduledoc """
  The current device. Should only ever be _one_ of these. If not there is a huge
  problem probably higher up the stack.
  """

  use FarmbotOS.Asset.Schema, path: "/api/device"

  schema "devices" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:timezone, :string)
    field(:ota_hour, :integer)
    field(:mounted_tool_id, :integer)
    field(:monitor, :boolean, default: true)
    field(:needs_reset, :boolean, default: false)
    field(:indoor, :boolean, default: false)
    field(:lat, :float, default: 0.0)
    field(:lng, :float, default: 0.0)
    timestamps()
  end

  view device do
    %{
      id: device.id,
      name: device.name,
      timezone: device.timezone,
      ota_hour: device.ota_hour,
      needs_reset: device.needs_reset,
      mounted_tool_id: device.mounted_tool_id,
      indoor: device.indoor,
      lat: device.lat,
      lng: device.lng
    }
  end

  def changeset(device, params \\ %{}) do
    device
    |> cast(params, [
      :id,
      :name,
      :timezone,
      :ota_hour,
      :mounted_tool_id,
      :monitor,
      :created_at,
      :updated_at,
      :needs_reset,
      :indoor,
      :lat,
      :lng
    ])
    |> validate_required([])
  end
end
