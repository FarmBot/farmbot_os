defmodule Counter do
  @moduledoc """
    Possible the laziest GenServer ever created.
  """
  defmacro __using__(mod) do
    quote do
      defp get_count,   do: GenServer.call Counter, {:get_count,   unquote(mod)}
      defp inc_count,   do: GenServer.cast Counter, {:inc_count,   unquote(mod)}
      defp dec_count,   do: GenServer.cast Counter, {:dec_count,   unquote(mod)}
      defp reset_count, do: GenServer.cast Counter, {:reset_count, unquote(mod)}
    end
  end

  use GenServer
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_state, do: GenServer.call(__MODULE__, :get_state)

  def init(_), do: {:ok, %{}}

  def handle_call(:get_state, _, state), do: {:reply, state, state}

  def handle_call({:get_count, m}, _, s) do
    if s[m], do: {:reply, s[m], s}, else: {:reply, 0, Map.put(s, m, 0)}
  end

  def handle_cast({:inc_count, mod}, state) do
    thing = lookup(state, mod)
    {:noreply, %{thing | mod => thing[mod] + 1}}
  end

  def handle_cast({:dec_count, mod}, state) do
    thing = lookup(state, mod)
    {:noreply, %{thing | mod => thing[mod] - 1}}
  end

  def handle_cast({:reset_count, m}, s), do: {:noreply, Map.put(s, m, 0)}

  # returns a state with this module
  defp lookup(s, m), do: if(s[m], do: s, else: Map.put(s, m, 0))
end
