defmodule FarmbotExt.MQTT.RPCHandler do
  use GenServer

  require FarmbotCore.Logger
  require FarmbotTelemetry
  require Logger

  alias FarmbotCeleryScript.{AST, StepRunner}
  alias FarmbotCore.JSON
  alias FarmbotExt.MQTT
  alias __MODULE__, as: State

  defstruct client_id: "NOT_SET", username: "NOT_SET", rpc_requests: %{}

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{
      client_id: Keyword.fetch!(args, :client_id),
      username: Keyword.fetch!(args, :username)
    }

    {:ok, state}
  end

  def handle_info({:inbound, [_, _, "from_clients"], payload}, state) do
    ast = JSON.decode!(payload) |> AST.decode()
    IO.puts("=== TODO: Dont crash on bad inut")
    channel_pid = self()
    ref = make_ref()
    _pid = spawn(StepRunner, :step, [channel_pid, ref, ast])

    timer =
      if ast.args[:timeout] && ast.args[:timeout] > 0 do
        msg = {:step_complete, {:error, "timeout"}}
        FarmbotExt.Time.send_after(self(), msg, ast.args[:timeout])
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
        FarmbotExt.Time.cancel_timer(timer)
        result_ast = %{kind: :rpc_ok, args: %{label: label}}
        send_reply(state, JSON.encode!(result_ast))
        {:noreply, %{state | rpc_requests: Map.delete(state.rpc_requests, ref)}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:step_complete, ref, {:error, reason}}, state) do
    Logger.error("CeleryScript error [#{inspect(ref)}]: #{inspect(reason)}")

    case state.rpc_requests[ref] do
      %{label: label, timer: timer} ->
        FarmbotExt.Time.cancel_timer(timer)

        result_ast = %{
          kind: :rpc_error,
          args: %{
            label: label
          },
          body: [
            %{kind: :explanation, args: %{message: reason}}
          ]
        }

        send_reply(state, JSON.encode!(result_ast))
        FarmbotCore.Logger.error(2, "Failed to execute command: #{reason}")
        {:noreply, %{state | rpc_requests: Map.delete(state.rpc_requests, ref)}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(req, state) do
    Logger.info("================ UNKNOWN MSG - #{inspect(req)}")
    {:noreply, state}
  end

  def send_reply(state, reply) do
    MQTT.publish(state.client_id, "bot/#{state.username}/from_device", reply)
  end
end
