defmodule FarmbotCore.FirmwareNeeds do
  @moduledoc """
    Keeps track of flags firmware needs to know about like:
    * Does the firmware need to be flashed?
    * Does the firmware need to be opened?

    This once lived within a config table, but these change too
    frequently for DirtyWorker / API row locking.
  """
  use GenServer

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    state = %{
      keys: %{
        needs_flash: true,
        needs_open:  true
      }
    }
    {:ok, state}
  end

  def flash?(), do: get(:needs_flash)
  def open?(), do: get(:needs_open)
  def flash(value), do: set(:needs_flash, value)
  def open(value), do: set(:needs_open, value)
  def get(key, mod \\ __MODULE__), do: GenServer.call(mod, {:get, key})
  def set(key, value, mod \\ __MODULE__), do: GenServer.call(mod, {:set, key, value})

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.fetch!(state[:keys], key), state}
  end

  def handle_call({:set, key, value}, _from, state) do
    next_keys = Map.put(state[:keys], key, value)
    next_state = Map.merge(state, %{keys: next_keys})

    {:reply, next_state, state}
  end
end