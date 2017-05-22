defmodule Farmbot.BotState.Supervisor do
  @moduledoc """
    Supervises the state tracker modules and an event manager that other
    things can subscribe too.
  """

  alias Farmbot.Context

  @use_logger Application.get_env(:farmbot, :logger, true)

  use Supervisor
  require Logger
  alias Farmbot.EasterEggs
  def init(ctx) do
    children = [
      worker(Farmbot.BotState.Monitor,
        [ctx, [name: Farmbot.BotState.Monitor]]),

      worker(Farmbot.BotState.Configuration,
        [ctx, [name: Farmbot.BotState.Configuration]]),

      worker(Farmbot.BotState.Hardware,
        [ctx, [name: Farmbot.BotState.Hardware]]),

      worker(EasterEggs,
        [name: EasterEggs])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start_link(%Context{} = ctx, opts) do
    # We have to start all the monitors and what not
    # and then add the logger backent because the logger backend asks for stuff
    # like position and some configuraion.
    sup = Supervisor.start_link(__MODULE__, ctx, opts)
    EasterEggs.start_cron_job
    if @use_logger, do: Logger.add_backend(Logger.Backends.FarmbotLogger)
    sup
  end
end
