defmodule Farmbot.Peripheral.Worker do
  use GenServer
  alias Farmbot.{Asset, Registry}
  import Farmbot.CeleryScript.Utils
  alias Asset.Peripheral
  require Farmbot.Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    Registry.subscribe()
    {:ok, %{}}
  end

  def handle_info({Registry, {Asset, {:deletion, %Peripheral{}}}}, state) do
    {:noreply, state}
  end

  def handle_info({Registry, {Asset, {_action, %Peripheral{label: label, id: id, mode: mode}}}}, state) do
    named_pin = ast(:named_pin, %{pin_type: "Peripheral", pin_id: id})
    read_pin = ast(:read_pin, %{pin_number: named_pin, label: label, pin_mode: mode})
    request = ast(:rpc_request, %{label: label}, [read_pin])
    Farmbot.Core.CeleryScript.rpc_request(request, fn(results) ->
      case results do
        %{kind: :rpc_ok} -> :ok
        %{kind: :rpc_error, body: [%{args: %{message: message}}]} ->
          Farmbot.Logger.error(1, "Error reading peripheral #{label} => #{message}")
      end
    end)
    {:noreply, state}
  end

  def handle_info({Registry, _}, state) do
    {:noreply, state}
  end
end
