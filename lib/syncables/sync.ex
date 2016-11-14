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
             :users]

   @type t :: %__MODULE__{
     compat_num:    number,
     device:        Device.t,
     peripherals:   list(Peripheral.t),
     plants:        list(Plant.t),
     regimen_items: list(RegimenItem.t),
     regimens:      list(Regimen.t),
     sequences:     list(Sequence.t),
     users:         list(User.t)
   }

  @spec create(map) :: t
  def create(%{"compat_num" =>    compat_num,
               "device" =>        device,
               "peripherals" =>   peripherals,
               "plants" =>        plants,
               "regimen_items" => regimen_items,
               "regimens" =>      regimens,
               "sequences" =>     sequences,
               "users" =>         users})
  when  is_integer(compat_num)
    and is_map(device)
    and is_list(peripherals)
    and is_list(plants)
    and is_list(regimen_items)
    and is_list(regimens)
    and is_list(sequences)
    and is_list(users)
  do
    %Sync{compat_num: compat_num,
          device: Device.create(device),
          plants: create_list(Plant,plants),
          regimen_items: create_list(RegimenItem,regimen_items),
          regimens: create_list(Regimen,regimens),
          sequences: create_list(Sequence,sequences),
          users: create_list(User,users),
          peripherals: create_list(Peripheral, peripherals)}
  end

  defp create_list(module, list) do
    Enum.map(list, fn(item) ->
      module.create(item)
    end)
  end
end
