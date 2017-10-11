defmodule Farmbot.BotState.Supervisor do
  use Supervisor

  def start_link(token, opts) do
    Supervisor.start_link(__MODULE__, token, opts)
  end

  def init(_token) do
    children = [
      supervisor(Farmbot.Firmware.Supervisor, [[name: Farmbot.Firmware.Supervisor]]),
      worker(Farmbot.BotState, [[name: Farmbot.BotState]]),
      worker(Farmbot.Logger, [[name: Farmbot.Logger]]),
      supervisor(Farmbot.BotState.Transport.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
