defmodule Farmbot.BotState.Supervisor do
  @moduledoc """
    Supervises the state tracker modules and an event manager that other
    things can subscribe too.
  """

  @use_logger Application.get_env(:farmbot, :logger, true)

  use Supervisor
  require Logger
  alias Farmbot.EasterEggs
  def init([]) do
    children = [
      worker(Farmbot.BotState.Monitor, [], [restart: :permanent]),
      worker(Farmbot.BotState.Configuration, [], [restart: :permanent]),
      worker(Farmbot.BotState.Hardware,  [], [restart: :permanent]),
      worker(Farmbot.BotState.ProcessSupervisor, [], [restart: :permanent]),
      worker(EasterEggs, [name: EasterEggs], [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start_link do
    # We have to start all the monitors and what not
    # and then add the logger backent because the logger backend asks for stuff
    # like position and some configuraion.
    sup = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    EasterEggs.start_cron_job
    if @use_logger, do: Logger.add_backend(Farmbot.Logger)
    sup
  end
end
