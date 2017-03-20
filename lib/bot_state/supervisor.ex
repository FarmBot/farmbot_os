defmodule Farmbot.BotState.Supervisor do
  @moduledoc """
    Supervises the state tracker modules and an event manager that other
    things can subscribe too.
  """

  @use_logger Application.get_env(:farmbot, :logger, true)

  use Supervisor
  require Logger
  alias Farmbot.EasterEggs
  def init(
    %{target: target,
      compat_version: compat_version,
      version: version,
      commit: commit})
  do
    children = [
      worker(Farmbot.BotState.Monitor, [], [restart: :permanent]),

      worker(Farmbot.BotState.Configuration, [
        %{compat_version: compat_version,
          target: target,
          version: version,
          commit: commit}
        ], [restart: :permanent]),

      worker(Farmbot.BotState.Hardware,  [], [restart: :permanent]),
      worker(Farmbot.BotState.ProcessSupervisor, [], [restart: :permanent]),
      worker(EasterEggs, [name: EasterEggs], [restart: :permanent])
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
    if @use_logger, do: Logger.add_backend(Farmbot.Logger)
    sup
  end
end
