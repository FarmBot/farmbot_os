defmodule Farmbot.Database.Syncable.Point do
  @moduledoc """
  A Point from the Farmbot API.
  """

  alias Farmbot.Context
  alias Farmbot.Database
  alias Database.{Syncable, Selectors}
  alias Selectors.Error, as: SelectorError
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
    context
    |> Database.get_all(__MODULE__)
    |> Enum.find(fn(%{body: point}) -> point.tool_id == tool_id end) ||
    raise SelectorError, syncable: __MODULE__, syncable_id: tool_id,
                         message: "Could not find tool_slot with tool_id: #{tool_id}"
  end
end
