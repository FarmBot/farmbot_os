defmodule Farmbot.BotState.Supervisor do
  @moduledoc """
      Supervises the state tracker modules and an event manager that other
      things can subscribe too.
  """

  use Supervisor
  require Logger
  alias Farmbot.EasterEggs
  def init(
    %{target: target, compat_version: compat_version, version: version})
  do
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
      worker(Farmbot.BotState.Configuration, [
        %{compat_version: compat_version,
          target: target,
          version: version}
        ], [restart: :permanent]),
      worker(Farmbot.BotState.Hardware,      [], [restart: :permanent]),
      worker(Farmbot.EasterEggs, [name: Farmbot.EasterEggs],
        [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start_link(args) do
    # We have to start all the monitors and what not
    # and then add the logger backent because the logger backend asks for stuff
    # like position and some configuraion.
    sup = Supervisor.start_link(__MODULE__, args, name: __MODULE__)
    EasterEggs.start_cron_job
    # Logger.add_backend(Farmbot.Logger) #FIXME add logger backend
    sup
  end
end
