defmodule Farmbot.Database.Syncable.Point do
  @moduledoc """
    A Point from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  use Syncable, model: [
    :pointer_type,
    :created_at,
    :tool_id,
    :radius,
    :name,
    :meta,
    :x,
    :y,
    :z,
  ], endpoint: {"/points", "/points"}

  def get_tool(_tool_id) do
    #FIXME
    nil
  end

  # THIS WAS A BAD_IDEA
  # alias Farmbot.Database.Syncable.Point

  # def to_tag(%Point{pointer_type: "GenericPointer"} = point), do: point
  #
  # def to_tag(%Point{pointer_type: pointer_type} = point) do
  #   mname = Module.concat([Point, pointer_type])
  #   mname |> struct(Map.from_struct(point))
  # end
end
