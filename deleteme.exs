defmodule F do
  use GenServer
  require Logger
  alias Farmbot.BotState.ProcessTracker, as: P
  def start_link(name) do
    Atom.to_string(name)
    GenServer.start_link(__MODULE__, [name], name: name)
  end

  def init([name]) do
    P.register(:event, name)
    {:ok, name}
  end

  def terminate(_reason, name) do
    pid = self()
    {uuid, ^pid} = P.lookup(:event, name)
    P.deregister(uuid)
  end
end
