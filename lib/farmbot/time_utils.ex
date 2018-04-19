defmodule Farmbot.TimeUtils do
  @moduledoc "Helper functions for working with time."

  def format_time(%DateTime{} = dt) do
    "#{format_num(dt.month)}/#{format_num(dt.day)}/#{dt.year} " <>
      "at #{format_num(dt.hour)}:#{format_num(dt.minute)}"
  end

  defp format_num(num), do: :io_lib.format('~2..0B', [num]) |> to_string

  # returns midnight of today
  @spec build_epoch(DateTime.t) :: DateTime.t
  def build_epoch(time) do
    import Farmbot.System.ConfigStorage, only: [get_config_value: 3]
    tz = get_config_value(:string, "settings", "timezone")
    n  = Timex.Timezone.convert(time, tz)
    Timex.shift(n, hours: -n.hour, seconds: -n.second, minutes: -n.minute)
  end
end
