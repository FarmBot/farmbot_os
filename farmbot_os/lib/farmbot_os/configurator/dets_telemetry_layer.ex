defmodule FarmbotOS.Configurator.DetsTelemetryLayer do
  @moduledoc """
  Telemetry layer implementation for fetching telemetry data from
  `farmbot_telemetry` OTP application.
  """

  @behaviour FarmbotOS.Configurator.TelemetryLayer

  @impl FarmbotOS.Configurator.TelemetryLayer
  def cpu_usage do
    [
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-21 19:43:31.830708Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-21 20:43:31.856517Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-21 21:43:31.857095Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-21 22:43:31.857596Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-21 23:43:31.858173Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-22 00:43:31.859040Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-22 01:43:31.859524Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-22 02:43:31.859929Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-22 03:43:31.860323Z],
        value: Enum.random(5..100)
      },
      %{
        class: FarmbotTelemetry.CPUUsageClass,
        timestamp: ~U[2019-10-22 04:43:31.860687Z],
        value: Enum.random(5..100)
      }
    ]
  end
end
