defmodule Farmbot.OS.IOLayer.Sync do
  import Farmbot.Config, only: [get_config_value: 3]
  import Farmbot.Asset, only: [fragment_sync: 1, full_sync: 2]
  require Farmbot.Logger
  alias Farmbot.HTTP
  alias Farmbot.Asset.{
    Device,
    FarmEvent,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool,
  }

  def execute(_, []) do
    case get_config_value(:bool, "settings", "needs_http_sync") do
      true -> full_sync(1, &http_sync/0)
      false -> fragment_sync(1)
    end
  end

  def http_sync do
    Farmbot.Logger.debug 3, "Starting HTTP sync."
    {time, results} = :timer.tc(fn() ->
      {:ok, pid} = Task.Supervisor.start_link()
      [
        Task.Supervisor.async_nolink(pid, fn -> {Device, HTTP.device() |> List.wrap() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {FarmEvent, HTTP.farm_events() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {Peripheral, HTTP.peripherals() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {PinBinding, HTTP.pin_bindings() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {Point, HTTP.points() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {Regimen, HTTP.regimens() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {Sensor, HTTP.sensors() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {Sequence, HTTP.sequences() |> list_to_sync_cmds()} end),
        Task.Supervisor.async_nolink(pid, fn -> {Tool, HTTP.tools() |> list_to_sync_cmds()} end),
      ]
      |> Enum.map(&Task.yield(&1))
      |> Enum.map(fn({:ok, {_kind, list}}) -> list end)
      |> List.flatten()
    end)
    Farmbot.Logger.debug 3, "HTTP requests took: #{time}us."
    {:ok, results}
  end

  def list_to_sync_cmds(list, acc \\ [])
  def list_to_sync_cmds([], results), do: results
  def list_to_sync_cmds([data | rest], acc) do
    list_to_sync_cmds(rest, [to_sync_cmd(data) | acc])
  end

  def to_sync_cmd(%kind{} = data) do
    kind = Module.split(kind)
    |> List.last()

    body = Map.from_struct(data)
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)

    Farmbot.Asset.new_sync_cmd(data.id, kind, body)
  end
end
