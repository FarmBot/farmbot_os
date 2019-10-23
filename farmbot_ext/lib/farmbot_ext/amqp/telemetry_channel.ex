defmodule FarmbotExt.AMQP.TelemetryChannel do
  @moduledoc """
  """
  use GenServer
  use AMQP

  alias FarmbotExt.AMQP.ConnectionWorker
  require FarmbotCore.Logger

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    Process.flag(:sensitive, true)
    jwt = Keyword.fetch!(args, :jwt)
    send(self(), :connect_amqp)

    state = %State{
      conn: nil,
      chan: nil,
      jwt: jwt
    }

    {:ok, state}
  end

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from Telemetry channel: #{inspect(reason)}")
    if state.chan, do: ConnectionWorker.close_channel(state.chan)
  end

  def handle_info(:connect_amqp, state) do
    bot = state.jwt.bot
    telemetry = bot <> "_telemetry"
    # route = "bot.#{bot}.telemetry"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, %{pid: channel_pid} = chan} <- Channel.open(conn),
         Process.link(channel_pid),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, telemetry, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, telemetry) do
      FarmbotCore.Logger.debug(3, "connected to Telemetry channel")
      send(self(), :consume_telemetry)
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil}}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to Telemetry channel: #{inspect(err)}")
        Process.send_after(self(), :connect_amqp, 2000)
        {:noreply, %{state | conn: nil, chan: nil}}
    end
  end

  def handle_info(:consume_telemetry, state) do
    _ =
      FarmbotTelemetry.consume_telemetry(fn
        {captured_at, kind, subsystem, measurement, value, meta} ->
          json =
            FarmbotCore.JSON.encode!(%{
              "telemetry.measurement" => measurement,
              "telemetry.value" => value,
              "telemetry.kind" => kind,
              "telemetry.subsystem" => subsystem,
              "telemetry.captured_at" => to_string(captured_at),
              "telemetry.meta" => %{meta | function: inspect(meta.function)}
            })

          Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.telemetry", json)
      end)

    _ = Process.send_after(self(), :consume_telemetry, 1000)
    {:noreply, state}
  end
end
