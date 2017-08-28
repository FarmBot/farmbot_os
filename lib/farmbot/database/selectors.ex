defmodule Farmbot.Database.Selectors do
  @moduledoc """
  Instead of litering the codebase with map/reduce/filter functions,
  consider putting database query functions into this module.
  """
  alias Farmbot.{Database, DebugLog}
  alias Database.RecordStorage
  alias Database.Syncable
  alias __MODULE__.Error, as: SelectorError
  alias Syncable.{Point, Device}
  use   DebugLog

  @doc """
  Find a Point with a particular type.
  * "Plant"
  * "ToolSlot"
  * "GenericPointer"
  """
  @spec find_point(GenServer.server(), binary, integer) :: Syncable.t | no_return
  def find_point(record_storage, "Plant"          = pt, id),
    do: do_find_point(record_storage, pt, id)

  def find_point(record_storage, "ToolSlot"       = pt, id),
    do: do_find_point(record_storage, pt, id)

  def find_point(record_storage, "GenericPointer" = pt, id),
    do: do_find_point(record_storage, pt, id)

  @spec do_find_point(GenServer.server(), binary, integer) :: Point.t
  defp do_find_point(record_storage, point_t, point_id) do
    result = RecordStorage.get_by_id(record_storage, Point, point_id) || raise SelectorError, [
      syncable: Point, syncable_id: point_id, message: "does not exist."
    ]

    case result.body.pointer_type do
      type when type == point_t -> result
      _ -> raise SelectorError, [
        syncable: Point, syncable_id: point_id, message: "does not match type: #{point_t}"
      ]
    end
  end

  @doc """
  Get this device. Raises.
  """
  @spec get_device(GenServer.server()) :: Syncable.body | no_return
  def get_device(record_storage) do
    case RecordStorage.get_all(record_storage, Device) do
      [device]      -> device.body
      [_device | _] ->
        raise SelectorError, [
          syncable: Device, syncable_id: nil, message: "Too many devices."
        ]
      [] ->
        raise SelectorError, [
          syncable: Device, syncable_id: nil, message: "No device."
        ]
    end
  end
end
