defmodule Blah do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def terminate(_, _) do
    Logger.error "#{__MODULE__} shutting down"
  end
end

defmodule Farmbot.Serial.Supervisor do
  @moduledoc "Supervisor for serial services."
  alias Farmbot.Context
  alias Farmbot.Serial.Handler.OpenTTY
  use   Context.Supervisor

  def init(%Context{} = ctx) do
    children = [
      worker(Task,
        [OpenTTY, :open_ttys, [ctx, __MODULE__]], restart: :transient),
      worker(Blah, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
