defmodule Farmbot.Sync.Database.Diff do
  @moduledoc """
    Takes two mapsets and does stuff if they are different
  """
  use GenServer
  @type state :: %{optional(atom) => {MapSet.t, MapSet.t}}

  @spec init(any) :: state
  def init(_), do: {:ok, Map.new()}

  @doc """
    Starts the Differ
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
    Gets the state
  """
  @spec get_state :: state
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @doc """
    Registers some structs.
  """
  @spec register([struct]) :: :ok
  def register(list_of_structs)
  def register([object | _t] = list) do
    GenServer.call(__MODULE__, {:register, object.__struct__, list})
  end

  @doc """
    Gets the diff for a Module, or by a list of structs
  """
  @spec diff(atom | [struct]) :: MapSet.t
  def diff(module_or_list_of_structs)
  def diff(module) when is_atom(module) do
    GenServer.call(__MODULE__, {:diff, module})
  end

  def diff([object | _t] = list) do
    :ok = register(list)
    diff(object.__struct__)
  end

  def diff([]), do: MapSet.new()

  # GenServer callbacks

  def handle_call(:get_state, _, state), do: {:reply, state, state}

  def handle_call({:register, module, list}, _, state) do
    new_set = MapSet.new(list)
    new_state =
      case state[module] do
        # when the flag is true replace set_a keep set_b & flip the flag
        {_set_a, set_b, true} -> %{state | module => {new_set, set_b, false}}
        # when the flag is false replace set_b keep set_a & flip the flag
        {set_a, _set_b, false} -> %{state | module => {set_a, new_set, true}}
        # if this key doesnt exist, just put the set in space a
        _ -> Map.put(state, module, {new_set, MapSet.new(), false})
      end
    {:reply, :ok, new_state}
  end

  def handle_call({:diff, module}, _, state) do
    case state[module] do
      # when module exists on state, Diff it
      {set_a, set_b, _flag} -> {:reply, MapSet.difference(set_a, set_b), state}
      # when it doesnt, create a new set, return it, and input it into the state
      _ ->
        set = MapSet.new()
        {:reply, set, state}
    end
  end
end
