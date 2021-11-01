defmodule FarmbotOS.MQTT.SyncHandler do
  require FarmbotOS.Logger
  require FarmbotTelemetry
  require Logger

  alias __MODULE__, as: State
  alias FarmbotOS.MQTT.SyncHandlerSupport, as: Support

  defstruct client_id: "NOT_SET", username: "NOT_SET", preloaded: false

  use GenServer

  @known_kinds ~w(
    Device
    FarmEvent
    FarmwareEnv
    FbosConfig
    FirmwareConfig
    Peripheral
    PinBinding
    Point
    PointGroup
    Regimen
    Sensor
    Sequence
    Tool
    )

  def start_link(default, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, default, opts)
  end

  def init(opts) do
    send(self(), :preload)

    state = %State{
      client_id: Keyword.fetch!(opts, :client_id),
      username: Keyword.fetch!(opts, :username)
    }

    {:ok, state}
  end

  def handle_info({:inbound, _, _}, %{preloaded: false} = state) do
    send(self(), :preload)
    {:noreply, state}
  end

  def handle_info(
        {:inbound, [_, _, "sync", kind, id_str], json},
        %{preloaded: true} = state
      )
      when kind in @known_kinds do
    Support.reply_to_sync_message(state, kind, id_str, json)
    {:noreply, state}
  end

  def handle_info(:preload, state), do: Support.preload_all(state)
  def handle_info(_other, state), do: {:noreply, state}
  def terminate(_reason, _state), do: Support.drop_all_cache()
end
