defmodule FarmbotOS.Configurator.TelemetryLayer do
  @moduledoc """
  intermediate layer for stubbing telemetry data
  """

  @doc "Returns current cpu usage"
  @callback cpu_usage :: [map()]
end
