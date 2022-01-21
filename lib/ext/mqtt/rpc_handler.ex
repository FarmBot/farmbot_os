defmodule FarmbotOS.MQTT.RPCHandler do
  use GenServer

  require FarmbotOS.Logger
  require FarmbotTelemetry
  require Logger

  alias FarmbotOS.Celery.AST
  alias FarmbotOS.JSON
  alias FarmbotOS.MQTT
  alias FarmbotOS.Time
  alias __MODULE__, as: State

  @timeoutmsg {:csvm_done, {:error, "timeout"}}

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
    channel_pid = self()
    ref = make_ref()
    _pid = spawn(fn -> FarmbotOS.Celery.execute(ast, ref, channel_pid) end)
    timeout = ast.args[:timeout] || 0
    has_timer? = timeout > 0
    timer = if has_timer?, do: Time.send_after(self(), @timeoutmsg, timeout)

    req = %{
      started_at: :os.system_time(),
      label: ast.args.label,
      timer: timer
    }

    {:noreply, %{state | rpc_requests: Map.put(state.rpc_requests, ref, req)}}
  end

  def handle_info({:csvm_done, ref, :ok}, state) do
    case state.rpc_requests[ref] do
      %{label: label, timer: timer} ->
        FarmbotOS.Time.cancel_timer(timer)
        result_ast = %{kind: :rpc_ok, args: %{label: label}}
        send_reply(state, JSON.encode!(result_ast))
        {:noreply, %{state | rpc_requests: Map.delete(state.rpc_requests, ref)}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:csvm_done, ref, {:error, reason}}, state) do
    Logger.error("CeleryScript error [#{inspect(ref)}]: #{inspect(reason)}")

    case state.rpc_requests[ref] do
      %{label: label, timer: timer} ->
        FarmbotOS.Time.cancel_timer(timer)

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
        FarmbotOS.Logger.error(2, "Failed to execute command: #{reason}")
        {:noreply, %{state | rpc_requests: Map.delete(state.rpc_requests, ref)}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(req, state) do
    Logger.info("#{inspect(__MODULE__)} Uncaught message: #{inspect(req)}")
    {:noreply, state}
  end

  def send_reply(state, reply) do
    MQTT.publish(state.client_id, "bot/#{state.username}/from_device", reply)
  end
end
