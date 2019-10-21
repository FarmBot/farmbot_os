defmodule FarmbotTelemetry.HTTPEventClass do
  @moduledoc """
  Classification of events pertaining to the Farmbot REST interface including:

  * sequences
  * farm events
  * regimens
  * etc
  """

  @behaviour FarmbotTelemetry.EventClass

  @impl FarmbotTelemetry.EventClass
  def matrix() do
    [
      farm_events: [:http_error, :http_timeout],
      farmware_installations: [:http_error, :http_timeout],
      regimens: [:http_error, :http_timeout],
      device: [:http_error, :http_timeout],
      diagnostic_dumps: [:http_error, :http_timeout],
      farm_events: [:http_error, :http_timeout],
      farmware_envs: [:http_error, :http_timeout],
      fbos_config: [:http_error, :http_timeout],
      firmware_config: [:http_error, :http_timeout],
      peripherals: [:http_error, :http_timeout],
      pin_bindings: [:http_error, :http_timeout],
      points: [:http_error, :http_timeout],
      public_keys: [:http_error, :http_timeout],
      sensor_readings: [:http_error, :http_timeout],
      sensors: [:http_error, :http_timeout],
      sequences: [:http_error, :http_timeout],
      sync: [:http_error, :http_timeout],
      tools: [:http_error, :http_timeout]
    ]
  end
end
