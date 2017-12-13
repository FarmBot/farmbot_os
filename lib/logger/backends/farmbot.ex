defmodule Logger.Backends.Farmbot do
  @moduledoc false

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, unformated_message, ts, metadata}}, state) do
    {{year, month, day}, {hour, minute, second, _millisecond}} = ts
    t =
      %DateTime{
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        calendar: Calendar.ISO,
        microsecond: {0, 0},
        second: second,
        std_offset: 0,
        time_zone: "Etc/UTC",
        utc_offset: 0,
        zone_abbr: "UTC"
      }
      |> DateTime.to_unix()

    module = metadata[:module]
    function = metadata[:function] || "no_function"
    verbosity = 3
    file = metadata[:file]
    line = metadata[:line]
    log = struct(Farmbot.Log,
      [
        time: t,
        level: level,
        verbosity: verbosity,
        message: format_message(unformated_message),
        meta: [], function: function,
        file: file, line: line,
        module: module
      ]
    )
    Farmbot.Logger.dispatch_log(log)
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp format_message(msg) when is_binary(msg) or is_atom(msg) do
    msg
  end

  defp format_message(msg) do
    msg |> to_string
  rescue
    _ -> inspect msg
  end
end
