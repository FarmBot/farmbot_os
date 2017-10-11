defmodule Logger.Backends.Farmbot do
  @moduledoc "Farmbot Loggerr Backend."
  alias Farmbot.Log

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, message, {{year, month, day}, {hour, minute, second, _millisecond}}, metadata}}, state) do
    mod_split = (metadata[:module] || Logger) |> Module.split()
    case mod_split do
      ["Farmbot" | _] ->
        t = %DateTime{year: year,
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
                  zone_abbr: "UTC"} |> DateTime.to_unix()
        l = %Log{message: message, channels: [level], created_at: t}
        GenStage.async_info(Farmbot.Logger, {:log, l})
      _ -> :ok
    end

    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

end
