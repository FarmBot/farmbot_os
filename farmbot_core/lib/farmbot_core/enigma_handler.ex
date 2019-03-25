defmodule FarmbotCore.EnigmaHandler do
  use GenServer

  @type enigma :: FarmbotCore.Assets.Private.Enigma.t()
  alias FarmbotCore.BotState

  @doc """
  The `up` callback will cause the EnigmaWorker to terminate if the
  callback returns `:ok`
  """
  @type enigma_up_callback :: (enigma -> :ok | {:error, term})
  @type enigma_down_callback :: (enigma -> :ok | {:error, term})

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def handle_up(handler \\ __MODULE__, enigma) do
    GenServer.call(handler, {:handle_up, enigma}, :infinity)
  end

  def handle_down(handler \\ __MODULE__, enigma) do
    GenServer.call(handler, {:handle_down, enigma}, :infinity)
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

  def handle_call({:handle_up, enigma}, _from, state) do
    :ok = BotState.add_enigma(enigma)
    case state[enigma.problem_tag] do
      {up, _down} when is_function(up, 1) ->
        {:reply, up.(enigma), state}
      _ -> {:reply, {:error, :no_handler}, state}
    end
  end

  def handle_call({:handle_down, enigma}, _from, state) do
    :ok = BotState.clear_enigma(enigma)
    case state[enigma.problem_tag] do
      {_up, down} when is_function(down, 1) ->
        {:reply, down.(enigma), state}
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
