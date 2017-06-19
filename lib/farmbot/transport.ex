alias Farmbot.BotState.Monitor.State, as: MonState
defmodule Farmbot.Transport do
  @moduledoc """
    Serializes Farmbot's state to be send out to any subscribed transports.
  """
  use GenStage
  require Logger
  use Farmbot.DebugLog
  alias Farmbot.Context

  # The max number of state updates before we force one
  @max_inactive_count 100

  defmodule Serialized do
    @moduledoc """
      Serialized Bot State
    """
    defstruct [:mcu_params,
               :location,
               :pins,
               :configuration,
               :informational_settings,
               :process_info,
               :user_env]

    @type t :: %__MODULE__{
      mcu_params: map,
      location: [integer, ...],
      pins: map,
      configuration: map,
      informational_settings: map,
      process_info: map,
      user_env: map}
  end

  def start_link(%Context{} = ctx, opts) do
    GenStage.start_link(__MODULE__, [ctx], opts)
  end

  def init([context]) do
    context = %{context | transport: self()}
    s = {%Serialized{}, 0, context}
    {:producer_consumer, s, subscribe_to: [context.monitor]}
  end

  def handle_call(:force_state_push, _from, {status, _, context}) do
    GenStage.async_notify(context.transport, {:status, status})
    {:reply, status, [], {status, 0, context}}
  end

  def handle_events(events, _from, state) do
    {:noreply, events, state}
  end

  defp translate(%MonState{} = monstate) do
    %Serialized{
      mcu_params:
        monstate.hardware.mcu_params,
      location:
        monstate.hardware.location,
      pins:
        monstate.hardware.pins,
      configuration:
        Map.delete(monstate.configuration.configuration, :user_env),
      informational_settings:
        monstate.configuration.informational_settings,
      process_info: monstate.process_info,
      user_env:
        monstate.configuration.configuration.user_env
    }
  end

  # Emit a message
  def handle_cast({:emit, thing}, {_status, _count, context} = state) do
    # don't Logger this because it will infinate loop.
    # just trust me.
    # logging a message here would cause logger to log a message, which
    # causes a state send which would then emit a message...
    debug_log "emmitting: #{inspect thing}"
    GenStage.async_notify(context.transport, {:emit, thing})
    {:noreply, [], state}
  end

  # Emit a log message
  def handle_cast({:log, log}, {_status, _count, context} = state) do
    GenStage.async_notify(context.transport, {:log, log})
    {:noreply, [], state}
  end

  def handle_info({_from, %MonState{} = monstate}, {old_status, count, context}) do
    new_status = translate(monstate)
    if (old_status == new_status) && (count < @max_inactive_count) do
      {:noreply, [], {old_status, count + 1, context}}
    else
      GenStage.async_notify(context.transport, {:status, new_status})
      {:noreply, [], {new_status, 0, context}}
    end
  end

  def handle_info(_event, state), do: {:noreply, [], state}

  @doc """
    Emit a message over all transports
  """
  @spec emit(Context.t, term) :: :ok
  def emit(%Context{} = ctx, message),
    do: GenStage.cast(ctx.transport, {:emit, message})

  @doc """
    Log a log message over all transports
  """
  @spec log(Context.t, term) :: :ok
  def log(%Context{} = ctx, message),
    do: GenStage.cast(ctx.transport, {:log, message})

  @doc """
    Force a state push
  """
  @spec force_state_push(Context.t) :: State.t
  def force_state_push(%Context{} = ctx),
    do: GenServer.call(ctx.transport, :force_state_push)
end
