defmodule FarmbotTelemetry.AMQPEventClass do
  @moduledoc """
  Classification of events pertaining to amqp channels including:

  * channel connections
  * channel disconnects
  * channel errors
  """

  @behaviour FarmbotTelemetry.EventClass

  @impl FarmbotTelemetry.EventClass
  def matrix() do
    channel_list = [
      :auto_sync,
      :celery_script,
      :bot_state,
      :logs,
      :nerves_hub
    ]

    [
      channel_connect: channel_list,
      channel_disconnect: channel_list,
      channel_error: channel_list
    ]
  end
end
