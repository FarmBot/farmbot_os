defmodule Syncables do
  defmacro __using__(_)
  do
    quote do
      alias Syncables.SyncObject
      alias Syncables.Device
      alias Syncables.Peripheral
      alias Syncables.RegimenItem
      alias Syncables.Regimen
      alias Syncables.Sequence
      alias Syncables.Token
      alias Syncables.ToolBay
      alias Syncables.ToolSlow
      alias Syncables.Tool
      alias Syncables.User
    end
  end

  defmodule Syncables.SyncObject do
    use Syncables
    use Syncable, name: __MODULE__, model:
    [ :device,
      :peripherals,
      :plants,
      :regimen_items,
      :regimens,
      :sequences,
      :users,
      :tool_bays,
      :tool_slots,
      :tools ]
    mutation :device,         do: Device.create(before)
    mutation :plants,         do: create_list(Plant,       before)
    mutation :regimen_items,  do: create_list(RegimenItem, before)
    mutation :regimens,       do: create_list(Regimen,     before)
    mutation :sequences,      do: create_list(Sequence,    before)
    mutation :users,          do: create_list(User,        before)
    mutation :peripherals,    do: create_list(Peripheral,  before)
    mutation :tool_bays,      do: create_list(ToolBay,     before)
    mutation :tool_slots,     do: create_list(ToolSlot,    before)
    mutation :tools,          do: create_list(Tool,        before)
    defp mutate(_, v), do: {:ok, v}

    defp create_list(m,[]), do: {:ok , []}
    defp create_list(m, l), do: {:ok, [ Enum.map(l, fn(item) -> m.create(item) end) ]}
  end

  defmodule Device,
    do: use Syncable, name: __MODULE__, model: [
      :id,
      :planting_area_id,
      :name,
      :webcam_url,
    ]

  defmodule Peripheral,
    do: use Syncable, name: __MODULE__, model: [
      :id,
      :device_id,
      :pin,
      :mode,
      :label,
      :created_at,
      :updated_at
    ]

  defmodule RegimenItem,
    do: use Syncable, name: __MODULE__, model: [
      :id, :time_offset, :regimen_id, :sequence_id
    ]

  defmodule Regimen,
    do: use Syncable, name: __MODULE__, model: [
      :id, :color, :name, :device_id,
    ]

  defmodule Sequence,
    do: use Syncable, name: __MODULE__, model: [
      :args,
      :body,
      :color,
      :device_id,
      :id,
      :kind,
      :name
    ]

  defmodule Token do
    use Syncable, name: __MODULE__, model: [:unencoded, :encoded]
    defmodule Unencoded do
      use Syncable, name: __MODULE__, model:
        [:bot,
         :exp,
         :fw_update_server,
         :os_update_server,
         :iat,
         :iss,
         :jti,
         :mqtt,
         :sub ]
    end

    mutation :unencoded, do: Unencoded.create(before)
    defp mutate(_, v), do: {:ok, v}
  end

  defmodule ToolBay,
    do: use Syncable, name: __MODULE__, model: [
      :id, :device_id, :name
    ]

  defmodule ToolSlot,
    do: use Syncable, name: __MODULE__, model: [
      :id, :tool_bay_id, :name, :x, :y, :z
    ]

  defmodule Tool, do: use Syncable, name: __MODULE__, model: [:id, :slot_id, :name]

  defmodule User,
    do: use Syncable, name: __MODULE__, model: [
      :id,
      :device_id,
      :name,
      :email,
      :created_at,
      :updated_at
    ]
end
