defmodule Farmbot.TimeUtils do
  def format_time(%DateTime{} = dt) do
    "#{format_num(dt.month)}/#{format_num(dt.day)}/#{dt.year} " <>
      "at #{format_num(dt.hour)}:#{format_num(dt.minute)}"
  end

  defp format_num(num), do: :io_lib.format('~2..0B', [num]) |> to_string
end
