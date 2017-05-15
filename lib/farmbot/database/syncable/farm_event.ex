defmodule Farmbot.Database.Syncable.FarmEvent do
  @moduledoc """
    A FarmEvent from the Farmbot API.
  """

  alias Farmbot.Database.Syncable
  use Syncable, model: [
    :start_time,
    :end_time,
    :repeat,
    :time_unit,
    :executable_id,
    :executable_type,
    :calendar
  ], endpoint: {"/farm_event", "/farm_events"}
end
