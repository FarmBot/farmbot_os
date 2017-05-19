defmodule Farmbot.Database.Selectors do
  @moduledoc """
    Instead of litering the codebase with map/reduce/filter functions,
    consider putting database query functions into this module.
  """
  alias Farmbot.Database
  alias Farmbot.Database.Syncable
  alias Farmbot.Context
  alias Syncable.Point

  @spec find_point(Context.t, binary, integer) :: Syncable.t
  # TODO(Rick): Add pattern match to DB param?
  def find_point(context, "Plant"          = pt, id), do: _find_point(context, pt, id)
  def find_point(context, "ToolSlot"       = pt, id), do: _find_point(context, pt, id)
  def find_point(context, "GenericPointer" = pt, id), do: _find_point(context, pt, id)

  @spec find_point(Context.t, binary, integer) :: Point.t
  defp _find_point(%Context{} = ctx, point_t, point_id) do
    result = Database.get_by_id(ctx, Point, point_id) || raise "" <>
      "Can't find #{point_t} with ID #{point_id}"

    case result.body.pointer_type do
      type when type == point_t -> result
      _ -> raise "POINT FAILURE: id/types don't match: #{point_id}/#{point_t}"
    end
  end
end
