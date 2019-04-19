defmodule FarmbotCore.AlertHandler do
  @moduledoc """
  Registers and deregisters a function that fires when an Alert is created or
  destroyed.
  """

  use GenServer

  # TODO(RickCarlino): Remote type does not exist. FIXME
  @type alert :: FarmbotCore.Assets.Private.Alert.t()
  alias FarmbotCore.BotState

  @doc """
  The `up` callback will cause the AlertWorker to terminate if the
  callback returns `:ok`
  """
  @type alert_up_callback :: (alert -> :ok | {:error, term})
  @type alert_down_callback :: (alert -> :ok | {:error, term})

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def handle_up(handler \\ __MODULE__, alert) do
    GenServer.call(handler, {:handle_up, alert}, :infinity)
  end

  def handle_down(handler \\ __MODULE__, alert) do
    GenServer.call(handler, {:handle_down, alert}, :infinity)
  end

  def register_up(handler \\ __MODULE__, problem_tag, fun)
    when is_binary(problem_tag)
    when is_function(fun, 1) do
    GenServer.call(handler, {:register_up, problem_tag, fun})
  end

  def register_down(handler \\ __MODULE__, problem_tag, fun)
    when is_binary(problem_tag)
    when is_function(fun, 1) do
    GenServer.call(handler, {:register_down, problem_tag, fun})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:handle_up, alert}, _from, state) do
    :ok = BotState.add_alert(alert)
    case state[alert.problem_tag] do
      {up, _down} when is_function(up, 1) ->
        {:reply, up.(alert), state}
      _ -> {:reply, {:error, :no_handler}, state}
    end
  end

  def handle_call({:handle_down, alert}, _from, state) do
    :ok = BotState.clear_alert(alert)
    case state[alert.problem_tag] do
      {_up, down} when is_function(down, 1) ->
        {:reply, down.(alert), state}
      _ -> {:reply, {:error, :no_handler}, state}
    end
  end

  def handle_call({:register_up, problem_tag, new_up}, _from, state) do
    {_, old_down} = state[problem_tag] || {nil, nil}
    new_handlers = {new_up, old_down}
    next_state = Map.put(state, problem_tag, new_handlers)
    {:reply, :ok, next_state}
  end

  def handle_call({:register_down, problem_tag, new_down}, _from, state) do
    {old_up, _} = state[problem_tag] || {nil, nil}
    new_handlers = {old_up, new_down}
    next_state = Map.put(state, problem_tag, new_handlers)
    {:reply, :ok, next_state}
  end
end
