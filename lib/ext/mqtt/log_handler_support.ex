defmodule FarmbotOS.MQTT.LogHandlerSupport do
  require FarmbotOS.Logger
  require Logger

  alias FarmbotOS.MQTT
  alias FarmbotOS.JSON

  # List extracted from:
  # https://github.com/FarmBot/Farmbot-Web-App/blob/b7f09e51e856bfca5cfedd7fef3c572bebdbe809/frontend/devices/actions.ts#L38
  @bad_words ~r(WPA|PSK|PASSWORD|NERVES)

  def maybe_publish_log(log, state) do
    if should_publish?(log) do
      publish_log(log, state)
    else
      :ok
    end
  end

  defp publish_log(log, state) do
    topic = "bot/#{state.username}/logs"
    MQTT.publish(state.client_id, topic, format_log(log, state))
  end

  defp format_log(log, state) do
    fb = %{position: %{x: nil, y: nil, z: nil}}
    location_data = Map.get(state.state_cache || %{}, :location_data, fb)
    %{position: %{x: x, y: y, z: z}} = location_data

    JSON.encode!(%{
      type: log.level,
      x: x,
      y: y,
      z: z,
      verbosity: log.verbosity,
      major_version: log.version.major,
      minor_version: log.version.minor,
      patch_version: log.version.patch,
      # QUESTION(Connor) - Why does this need `.to_unix()`?
      # ANSWER(Connor) - because the FE needed it.
      created_at:
        DateTime.from_naive!(log.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      channels: log.meta[:channels] || log.meta["channels"] || [],
      meta: %{
        assertion_passed: log.meta[:assertion_passed],
        assertion_type: log.meta[:assertion_type]
      },
      message: log.message
    })
  end

  defp should_publish?(log) do
    should_log? = FarmbotOS.Logger.should_log?(log.module, log.verbosity)
    clean? = !Regex.match?(@bad_words, String.upcase(log.message))
    should_log? && clean?
  end
end
