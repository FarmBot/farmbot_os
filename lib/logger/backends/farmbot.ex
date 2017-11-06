defmodule Logger.Backends.Farmbot do
  @moduledoc "Farmbot Loggerr Backend."
  alias Farmbot.Log
  @blacklist [__MODULE__,
              Farmbot.BotState.Transport.GenMQTT.Client]

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, _msg, _, metadata} = log}, state) do
    module = (metadata[:module] || Logger)
    if module in @blacklist do
      :ok
    else
      do_log(Module.split(module), level, log)
    end
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp do_log(["Farmbot" | _], level, {_, unformated_message, timestamp, meta}) do
    {{year, month, day}, {hour, minute, second, _millisecond}} = timestamp
    message = format_message(unformated_message)
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
    l = Log.new(message, t, meta[:channels] || [:ticker], meta[:message_type] || level)
    GenStage.async_info(Farmbot.Logger, {:log, l})
  end

  defp do_log(_, _level, _msg), do: :ok

  defp format_message(msg) when is_binary(msg) or is_atom(msg) do
    msg
  end

  defp format_message(msg) do
    msg |> to_string
  rescue
    _ -> inspect msg
  end
end
