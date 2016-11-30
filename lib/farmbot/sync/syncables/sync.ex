defmodule Sync do
  @moduledoc """
    The enitre Sync Object.
    located at /api/sync
  """
  defstruct [:compat_num,
             :device,
             :peripherals,
             :plants,
             :regimen_items,
             :regimens,
             :sequences,
             :users,
             :tool_bays,
             :tool_slots,
             :tools
          ]

   @type t :: %__MODULE__{
     compat_num:    integer,
     device:        Device.t,
     peripherals:   list(Peripheral.t),
     plants:        list(Plant.t),
     regimen_items: list(RegimenItem.t),
     regimens:      list(Regimen.t),
     sequences:     list(Sequence.t),
     users:         list(User.t),
     tool_bays:     list(Toolbay.t),
     tool_slots:    list(ToolSlot.t),
     tools:         list(Tool.t)
   }

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(%{"compat_num" =>    compat_num,
               "device" =>        device,
               "peripherals" =>   peripherals,
               "plants" =>        plants,
               "regimen_items" => regimen_items,
               "regimens" =>      regimens,
               "sequences" =>     sequences,
               "users" =>         users,
               "tool_bays" =>     tool_bays,
               "tool_slots" =>    tool_slots,
               "tools" =>         tools })
  when  is_integer(compat_num)
    and is_map(device)
    and is_list(peripherals)
    and is_list(plants)
    and is_list(regimen_items)
    and is_list(regimens)
    and is_list(sequences)
    and is_list(users)
    and is_list(tool_bays)
    and is_list(tool_slots)
    and is_list(tools)
  do
    f =
    %__MODULE__{
      compat_num:    compat_num,
      device:        Device.create!(device),
      plants:        create_list(Plant,plants),
      regimen_items: create_list(RegimenItem,regimen_items),
      regimens:      create_list(Regimen,regimens),
      sequences:     create_list(Sequence,sequences),
      users:         create_list(User,users),
      peripherals:   create_list(Peripheral, peripherals),
      tool_bays:     create_list(Toolbay, tool_bays),
      tool_slots:    create_list(ToolsSlot, tool_slots),
      tools:         create_list(Tool, tools) }
    {:ok, f}
  end

  def create(_), do: {__MODULE__, :malformed}

  @spec create!(map) :: t
  def create!(thing) do
    case create(thing) do
      {:ok, success} -> success
      {__MODULE__, :malformed} -> raise "Malformed #{__MODULE__} Object"
    end
  end

  defp create_list(m, l), do: Enum.map(l, fn(item) -> m.create!(item) end)
end
