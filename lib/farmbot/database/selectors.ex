defmodule Farmbot.Database.Selectors do
  @moduledoc """
    Instead of litering the codebase with map/reduce/filter functions,
    consider putting database query functions into this module.
  """
  alias Farmbot.Database
  alias Farmbot.Database.Syncable
  alias Syncable.Point


  @spec find_point(Database.data_base, binary, integer) :: Syncable.t
  # TODO(Rick): Add pattern match to DB param?
  def find_point(db, "Plant"          = pt, id), do: _find_point(db, pt, id)
  def find_point(db, "ToolSlot"       = pt, id), do: _find_point(db, pt, id)
  def find_point(db, "GenericPointer" = pt, id), do: _find_point(db, pt, id)

  @spec find_point(pid, binary, integer) :: Point.t
  defp _find_point(db, point_t, point_id) do
    result = Database.get_by_id(db, Point, point_id) || raise "" <>
      "Can't find #{point_t} with ID #{point_id}"

    case result.body.point_type do
      point_t -> result
      _       -> raise "POINT FAILURE: id/types don't match: " <>
                       "#{point_id}/#{point_t}"
    end
  end
end
