defmodule Farmbot.Database.Selectors do
  @moduledoc """
    Instead of litering the codebase with map/reduce/filter functions,
    consider putting database query functions into this module.
  """
  alias Farmbot.{Database, Context, DebugLog}
  alias Farmbot.Database.Syncable
  alias __MODULE__.Error, as: SelectorError
  alias Syncable.{Point, Device}
  use   DebugLog

  @doc """
    Find a Point with a particular type.
    * "Plant"
    * "ToolSlot"
    * "GenericPointer"
  """
  @spec find_point(Context.t, binary, integer) :: Syncable.t | no_return
  def find_point(%Context{} = context, "Plant"          = pt, id),
    do: do_find_point(context, pt, id)

  def find_point(%Context{} = context, "ToolSlot"       = pt, id),
    do: do_find_point(context, pt, id)

  def find_point(%Context{} = context, "GenericPointer" = pt, id),
    do: do_find_point(context, pt, id)

  @spec do_find_point(Context.t, binary, integer) :: Point.t
  defp do_find_point(%Context{} = ctx, point_t, point_id) do
    result = Database.get_by_id(ctx, Point, point_id) || raise SelectorError, [
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
  @spec get_device(Context.t) :: Syncable.body | no_return
  def get_device(%Context{} = ctx) do
    case Database.get_all(ctx, Device) do
      [device]      -> device.body
      [_device | _] ->
        raise SelectorError, [
          syncable: Device, syncable_id: nil, message: "Too many devices."
        ]
      [] ->
        raise SelectorError, [
          syncable: Device, syncable_id: nil, message: "No devices."
        ]
    end
  end
end
