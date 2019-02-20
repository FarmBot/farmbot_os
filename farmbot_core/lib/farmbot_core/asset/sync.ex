defmodule Elixir.Farmbot.Asset.Sync do
  @moduledoc """
  """

  use Farmbot.Asset.Schema, path: "/api/device/sync"

  defmodule Item do
    @moduledoc false
    use Ecto.Schema

    @primary_key false
    @behaviour Farmbot.Asset.View
    import Farmbot.Asset.View, only: [view: 2]

    view sync_item do
      %{
        id: sync_item.id,
        updated_at: sync_item.updated_at
      }
    end

    embedded_schema do
      field(:id, :id)
      field(:updated_at, :utc_datetime)
    end

    def changeset(item, params \\ %{})

    def changeset(item, [id, updated_at]) do
      changeset(item, %{id: id, updated_at: updated_at})
    end

    def changeset(item, params) do
      item
      |> cast(params, [:id, :updated_at])
      |> validate_required([])
    end
  end

  schema "syncs" do
    embeds_many(:devices, Item)
    embeds_many(:firmware_configs, Item)
    embeds_many(:fbos_configs, Item)
    embeds_many(:diagnostic_dumps, Item)
    embeds_many(:farm_events, Item)
    embeds_many(:farmware_envs, Item)
    embeds_many(:farmware_installations, Item)
    embeds_many(:peripherals, Item)
    embeds_many(:pin_bindings, Item)
    embeds_many(:points, Item)
    embeds_many(:regimens, Item)
    embeds_many(:sensor_readings, Item)
    embeds_many(:sensors, Item)
    embeds_many(:sequences, Item)
    embeds_many(:tools, Item)
    field(:now, :utc_datetime)
    timestamps()
  end

  view sync do
    %{
      devices: Enum.map(sync.device, &Item.render/1),
      fbos_configs: Enum.map(sync.fbos_config, &Item.render/1),
      firmware_configs: Enum.map(sync.firmware_config, &Item.render/1),
      diagnostic_dumps: Enum.map(sync.diagnostic_dumps, &Item.render/1),
      farm_events: Enum.map(sync.farm_events, &Item.render/1),
      farmware_envs: Enum.map(sync.farmware_envs, &Item.render/1),
      farmware_installations: Enum.map(sync.farmware_installations, &Item.render/1),
      peripherals: Enum.map(sync.peripherals, &Item.render/1),
      pin_bindings: Enum.map(sync.pin_bindings, &Item.render/1),
      points: Enum.map(sync.points, &Item.render/1),
      regimens: Enum.map(sync.regimens, &Item.render/1),
      sensor_readings: Enum.map(sync.sensor_readings, &Item.render/1),
      sensors: Enum.map(sync.sensors, &Item.render/1),
      sequences: Enum.map(sync.sequences, &Item.render/1),
      tools: Enum.map(sync.tools, &Item.render/1),
      now: sync.now
    }
  end

  def changeset(sync, params \\ %{}) do
    sync
    |> cast(params, [:now])
    |> cast_embed(:devices)
    |> cast_embed(:fbos_configs)
    |> cast_embed(:firmware_configs)
    |> cast_embed(:diagnostic_dumps)
    |> cast_embed(:farm_events)
    |> cast_embed(:farmware_envs)
    |> cast_embed(:farmware_installations)
    |> cast_embed(:peripherals)
    |> cast_embed(:pin_bindings)
    |> cast_embed(:points)
    |> cast_embed(:regimens)
    |> cast_embed(:sensor_readings)
    |> cast_embed(:sensors)
    |> cast_embed(:sequences)
    |> cast_embed(:tools)
    |> validate_required([])
  end
end
