defmodule FarmbotOS.Asset.FarmEvent.Calendar do
  defstruct [:end_sec, :events, :grace_period, :start_sec, :step]

  @max_generated 500
  @one_min 60

  def new(now_sec, end_sec, repeat, repeat_freq_sec, start_sec) do
    initial = %__MODULE__{
      start_sec: start_sec,
      end_sec: end_sec,
      grace_period: now_sec - @one_min,
      events: [],
      step: repeat_freq_sec * repeat
    }

    Enum.reduce_while(1..@max_generated, initial, &reduce/2).events
  end

  defp reduce(_, s) do
    if s.start_sec < s.end_sec do
      # if this event (i) is after the grace period, add it to the array.
      updates =
        if s.start_sec > s.grace_period do
          %{
            events: s.events ++ [s.start_sec],
            start_sec: s.start_sec + s.step
          }
        else
          %{start_sec: s.start_sec + s.step}
        end

      {:cont, Map.merge(s, updates)}
    else
      {:halt, s}
    end
  end
end
