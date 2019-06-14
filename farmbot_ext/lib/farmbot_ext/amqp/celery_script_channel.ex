defmodule FarmbotExt.AMQP.CeleryScriptChannel do
  @moduledoc """
  Handles inbound CeleryScript RPCs (from user via AMQP/MQTT).
  """

  use GenServer
  use AMQP

  alias FarmbotCore.JSON
  require FarmbotCore.Logger
  require Logger

  alias FarmbotCeleryScript.{AST, StepRunner}
  alias FarmbotExt.AMQP.ConnectionWorker

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt, :rpc_requests]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    Process.flag(:sensitive, true)
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, rpc_requests: %{}}, 0}
  end

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from CeleryScript channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  def handle_info(:timeout, state) do
    status = ConnectionWorker.maybe_connect_celeryscript(state.jwt.bot)
    compute_reply_from_amqp_state(state, status)
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    FarmbotCore.Logger.success(1, "Farmbot is up and running!")
    {:noreply, state}
  end

  # Sent by the broker when the consumer is
  # unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    device = state.jwt.bot
    ["bot", ^device, "from_clients"] = String.split(key, ".")
    ast = JSON.decode!(payload) |> AST.decode()

    channel_pid = self()
    ref = make_ref()
    _pid = spawn(StepRunner, :step, [channel_pid, ref, ast])

    timer =
      if ast.args[:timeout] && ast.args[:timeout] > 0 do
        msg = {:step_complete, {:error, "timeout"}}
        Process.send_after(self(), msg, ast.args[:timeout])
      end

    req = %{
      started_at: :os.system_time(),
      label: ast.args.label,
      timer: timer
    }

    {:noreply, %{state | rpc_requests: Map.put(state.rpc_requests, ref, req)}}
  end

  def handle_info({:step_complete, ref, :ok}, state) do
    Logger.info("CeleryScript ok [#{inspect(ref)}]: ")

    case state.rpc_requests[ref] do
      %{label: label, timer: timer} ->
        # label != "ping" && Logger.debug("CeleryScript success: #{label}")
        timer && Process.cancel_timer(timer)

        result_ast = %{
          kind: :rpc_ok,
          args: %{
            label: label
          }
        }

        reply = JSON.encode!(result_ast)
        AMQP.Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.from_device", reply)
        {:noreply, %{state | rpc_requests: Map.delete(state.rpc_requests, ref)}}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info({:step_complete, ref, {:error, reason}}, state) do
    Logger.error("CeleryScript error [#{inspect(ref)}]: #{inspect(reason)}")

    case state.rpc_requests[ref] do
      %{label: label, timer: timer} ->
        timer && Process.cancel_timer(timer)

        result_ast = %{
          kind: :rpc_error,
          args: %{
            label: label
          },
          body: [
            %{kind: :explanation, args: %{message: reason}}
          ]
        }

        reply = JSON.encode!(result_ast)
        AMQP.Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.from_device", reply)
        msg = ["CeleryScript Error\n", reason]
        Logger.error(msg)
        {:noreply, %{state | rpc_requests: Map.delete(state.rpc_requests, ref)}}

      nil ->
        {:noreply, state}
    end
  end

  defp compute_reply_from_amqp_state(state, %{conn: conn, chan: chan}) do
    {:noreply, %{state | conn: conn, chan: chan}}
  end

  defp compute_reply_from_amqp_state(state, error) do
    # Run error warning if error not nil
    if error,
      do: FarmbotCore.Logger.error(1, "Failed to connect to AutoSync channel: #{inspect(error)}")

    {:noreply, %{state | conn: nil, chan: nil}}
  end
end
