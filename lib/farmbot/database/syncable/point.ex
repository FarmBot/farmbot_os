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
end
