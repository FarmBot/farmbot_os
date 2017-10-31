defmodule Farmbot.BotState.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      supervisor(Farmbot.Firmware.Supervisor, []),
      worker(Farmbot.BotState, []),
      worker(Farmbot.Logger,   []),
      supervisor(Farmbot.BotState.Transport.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
