defmodule Farmbot.Sync.Cache do
   @moduledoc """
    Keeps a cache of what needs to be synced.
   """
   require Logger
   use GenServer
   alias Farmbot.CeleryScript.Command.DataUpdate
   @type syncable :: DataUpdate.syncable

   @type state :: %{
     optional(syncable) => {syncable, binary | [non_neg_integer]}
   }

   def start_link do
     GenServer.start_link(__MODULE__, [],  name: __MODULE__)
   end

   def init([]) do
     {:ok, %{}}
   end

   @doc """
   adds a map of sync things or something
   """
   @spec add([DataUpdate.sync_cache_map], DataUpdate.verb)
    :: :ok | no_return
   def add(list, verb) do
     GenServer.call(__MODULE__, {:add, list, verb})
   end

   @doc """
   Gets the state
   """
   @spec get_state :: state
   def get_state do
     GenServer.call(__MODULE__, :get_state)
   end

   @doc """
   Clears the cache
   """
   @spec clear :: :ok | no_return
   def clear, do: GenServer.call(__MODULE__, :clear)

   def handle_call(:get_state, _, state), do: {:reply, state, state}

   def handle_call(:clear, _from, _state) do
     {:reply, :ok, %{}}
   end

   def handle_call({:add, list, verb}, _from, old_state) do
     new_state = Enum.reduce(list, old_state, fn(cache_map, state) ->
       case cache_map.value do
         "*" ->
           Map.put(state, cache_map.syncable, [{verb, "*"}])
         number ->
           old = Map.get(state, cache_map.syncable, [])
           Map.put(state, cache_map.syncable, [{verb, number} | old])
       end
     end)

     {:reply, :ok, new_state}
   end
end
