defmodule FarmbotOS.Configurator.LoggerSocket do
  alias FarmbotOS.Configurator.LoggerSocket.LoggerBackend
  require Logger

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
    send(self(), :after_connect)
    {:ok, %{}}
  end

  def websocket_handle({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, json} ->
        websocket_handle({:json, json}, state)

      _ ->
        _ = Logger.debug("discarding info: #{message}")
        {:ok, state}
    end
  end

  def websocket_info(:after_connect, state) do
    Logger.add_backend(LoggerBackend)
    LoggerBackend.register()
    {:ok, state}
  end

  def websocket_info({level, _pid, {Logger, msg, timestamp, metadata}}, state) do
    {{year, month, day}, {hour, minute, second, _millisecond}} = timestamp

    datetime = %DateTime{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      time_zone: "Etc/UTC",
      std_offset: 0,
      zone_abbr: "UTC",
      utc_offset: 0
    }

    metadata =
      Keyword.take(metadata, [
        :module,
        :function,
        :file,
        :line,
        :application
      ])

    log =
      Jason.encode!(%{
        level: level,
        message: IO.iodata_to_binary(msg),
        datetime: datetime,
        metadata: Map.new(metadata)
      })

    {:reply, {:text, log}, state}
  end

  def websocket_info(info, state) do
    Logger.info("Dropping #{inspect(info)}")
    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end
end
