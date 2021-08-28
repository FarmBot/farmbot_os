defmodule FarmbotCore.Asset.FarmEvent.Calendar do
  @max_generated 500
  @one_min 60

  defstruct [
    :start_time_seconds,
    :end_t_sec,
    :grace_per_s,
    :events,
    :step
  ]

  def new(
        curr_t_sec,
        end_t_sec,
        repeat,
        repeat_frequency_sec,
        start_time_seconds
      ) do
    initial = %__MODULE__{
      start_time_seconds: start_time_seconds,
      end_t_sec: end_t_sec,
      grace_per_s: curr_t_sec - @one_min,
      events: [],
      step: repeat_frequency_sec * repeat
    }

    Enum.reduce_while(1..@max_generated, initial, &reduce/2).events
  end

  defp reduce(_, s) do
    if s.start_time_seconds < s.end_t_sec do
      # if this event (i) is after the grace period, add it to the array.
      updates =
        if s.start_time_seconds > s.grace_per_s do
          %{
            events: s.events ++ [s.start_time_seconds],
            start_time_seconds: s.start_time_seconds + s.step
          }
        else
          %{start_time_seconds: s.start_time_seconds + s.step}
        end

      {:cont, Map.merge(s, updates)}
    else
      {:halt, s}
    end
  end
end
