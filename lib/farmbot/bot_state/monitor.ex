defmodule Farmbot.BotState.Monitor do
  @moduledoc """
    this is the master state tracker. It receives the states from
    various modules, and then pushes updated state to anything that cares
  """
  alias Farmbot.BotState.Hardware.State, as: Hardware
  use GenServer
  require Logger

  defmodule State do
    alias Farmbot.BotState.Hardware.State, as: Hardware
    defstruct [
      hardware: %Hardware{}
    ]
  end

  def init(mgr) do
    :ok = add_handler(mgr, DefaultHandler, [])
    {:ok, {mgr, %State{}}}
  end

  def start_link(mgr) do
    GenServer.start_link(__MODULE__, mgr, name: __MODULE__)
  end

  def add_handler(mgr, module, args) do
    GenEvent.add_mon_handler(mgr, module, args)
  end

  def add_handler(module, args) do
    GenServer.cast(__MODULE__, {:add_handler, module, args})
  end

  def handle_cast({:add_handler, module, args}, {mgr, state}) do
    add_handler(mgr, module, args)
    GenEvent.notify(:event_manager, {:dispatch, state})
    {:noreply, {mgr, state}}
  end

  def handle_cast(%Hardware{} = new_things, {mgr, state}) do
    new_state = %State{state | hardware: new_things}
    GenEvent.notify(:event_manager, {:dispatch, new_state})
    {:noreply, {mgr, new_state}}
  end
end
