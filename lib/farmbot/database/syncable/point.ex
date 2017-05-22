defmodule Farmbot.Database.Syncable.Point do
  @moduledoc """
    A Point from the Farmbot API.
  """

  alias Farmbot.Context
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

  @doc """
    Turn a tool into a Point.
  """
  def get_tool(%Context{} = context, tool_id) do
    all         = Database.get_all context, __MODULE__

    maybe_point = Enum.find all, fn(%{body: point}) ->
      point.tool_id == tool_id
    end

    unless maybe_point do
      raise "Could not find tool_slot with tool_id: #{tool_id}"
    end

    maybe_point
  end
end
