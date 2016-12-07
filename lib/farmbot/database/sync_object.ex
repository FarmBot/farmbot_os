alias Farmbot.Sync.Database, as: DB
defmodule Farmbot.Sync.SyncObject do
  @moduledoc """
    I dont want this to be a database object but i want to have a good
    interface for it.
  """
  @type t :: %__MODULE__{}
  @keys [
    :device,
    :peripherals,
    :plants,
    :regimen_items,
    :regimens,
    :sequences,
    :tool_bays,
    :tool_slots,
    :tools,
    :users ]
  defstruct @keys

  @doc """
    Validates and creates a Farmbot SyncObject.
  """
  @spec validate({:ok, map} | map | any) :: {:ok, t} | {:error, atom}
  def validate({:ok, map}), do: validate(map)

  def validate(
    %{"device" => json_device,
      "peripherals" => json_peripherals,
      "plants" => json_plants,
      "regimen_items" => json_regimen_items,
      "regimens" => json_regimens,
      "sequences" => json_sequences,
      "tool_bays" => json_tool_bays,
      "tool_slots" => json_tool_slots,
      "tools" => json_tools,
      "users" => json_users})
  do
    with {:ok, device}        <- DB.Device.validate(json_device),
         {:ok, peripherals}   <- validate_list(DB.Peripheral,  json_peripherals),
         {:ok, plants}        <- validate_list(DB.Plant,       json_plants),
         {:ok, regimen_items} <- validate_list(DB.RegimenItem, json_regimen_items),
         {:ok, regimens}      <- validate_list(DB.Regimen,     json_regimens),
         {:ok, sequences}     <- validate_list(DB.Sequence,    json_sequences),
         {:ok, tool_bays}     <- validate_list(DB.ToolBay,     json_tool_bays),
         {:ok, tool_slots}    <- validate_list(DB.ToolSlot,    json_tool_slots),
         {:ok, tools}         <- validate_list(DB.Tool,        json_tools),
         {:ok, users}         <- validate_list(DB.User,        json_users)
         do
           f =
             %__MODULE__{
               device:        device,
               peripherals:   peripherals,
               plants:        plants,
               regimen_items: regimen_items,
               regimens:      regimens,
               sequences:     sequences,
               tool_bays:     tool_bays,
               tool_slots:    tool_slots,
               tools:         tools,
               users:         users }
           {:ok, f}
         end
  end

  def validate(thing) when is_map(thing) do
    req_string_keys = Enum.map(@keys, fn(key) -> Atom.to_string(key) end)
    given_keys = Map.keys(thing)
    {:error, {:bad_keys, given_keys -- req_string_keys}}
  end

  def validate(_), do: {:error, :bad_map}

  def validate!(map) do
    case validate(map) do
      {:ok, res} -> res
      error -> raise "Invalid Sync Object! #{inspect error}"
    end
  end

  def validate_list(module, list) do
    Enum.partition(list, fn(thing) ->
      case module.validate(thing) do
        {:ok, thing} -> thing
        error -> false
      end
    end)
    |> validate_partition(module)
  end

  def validate_partition({win, []}, _module), do: {:ok, win}
  def validate_partition({_, failed}, module), do: {:error, module, failed}
end
