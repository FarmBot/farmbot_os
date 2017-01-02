defmodule Farmbot.BotState.Supervisor do
  @moduledoc """
      Supervises the state tracker modules and an event manager that other
      things can subscribe too.
  """

  use Supervisor
  require Logger
  alias Farmbot.EasterEggs
  def init(initial_config) do
    children = [
      # Event manager.
      worker(GenEvent,
        [[name: Farmbot.BotState.EventManager]],
         [id: Farmbot.BotState.EventManager]),

      # the name of this is wrong now, but it subscribes the the
      # Event manager and serializes the state
      worker(Farmbot.BotState.Monitor,
        [Farmbot.BotState.EventManager], [restart: :permanent]),

      # These are the actual trackers for the different parts of the system.
      worker(Farmbot.BotState.Configuration,
        [initial_config], [restart: :permanent]),
      # worker(Farmbot.BotState.Authorization, [[]], [restart: :permanent]),
      worker(Farmbot.BotState.Hardware,      [[]], [restart: :permanent]),
      # worker(Farmbot.BotState.Network,       [[]], [restart: :permanent]),
      worker(Farmbot.EasterEggs, [name: Farmbot.EasterEggs],
        [restart: :permanent])
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link(args) do
    # We have to start all the monitors and what not
    # and then add the logger backent because the logger backend asks for stuff
    # like position and some configuraion.
    sup = Supervisor.start_link(__MODULE__, args)
    EasterEggs.start_cron_job
    Logger.add_backend(Farmbot.Logger)
    sup
  end
end
