defmodule FarmbotOS.Asset.Sensor do
  @moduledoc """
  Sensors are descriptors for pins/modes.
  """

  use FarmbotOS.Asset.Schema, path: "/api/sensors"

  schema "sensors" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:pin, :integer)
    field(:mode, :integer)
    field(:label, :string)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view sensor do
    %{
      id: sensor.id,
      pin: sensor.pin,
      mode: sensor.mode,
      label: sensor.label
    }
  end

  def changeset(sensor, params \\ %{}) do
    sensor
    |> cast(params, [
      :id,
      :pin,
      :mode,
      :label,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([:id, :pin, :mode, :label])
  end

  defimpl String.Chars, for: FarmbotOS.Asset.Sensor do
    def to_string(%FarmbotOS.Asset.Sensor{pin: pin, label: label}) do
      "Sensor #{label} Pin: #{pin}"
    end
  end
end
