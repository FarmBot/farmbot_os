defmodule TestGenServer do
  use GenServer
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end
  def init(:ok) do
    {:ok, :fake_state}
  end
  def hadnle_call(:am_i_connected, _, state) do
    {:reply, :true, state}
  end
  def handle_call(_,_,state) do
    {:reply, :ok, state}
  end
  def handle_cast(_, state) do
    {:noreply, state}
  end
  def handle_info(_,state) do
    {:noreply, state}
  end
end
