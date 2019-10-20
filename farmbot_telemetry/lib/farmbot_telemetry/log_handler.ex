defmodule FarmbotTelemetry.LogHandler do
  @moduledoc false
  require Logger

  def handle_event([class, type], %{action: action, timestamp: _timestamp}, meta, config) do
    message = "#{class}.#{type}.#{action}"
    Logger.bare_log(config[:level], message, Map.to_list(meta))
  end
end
