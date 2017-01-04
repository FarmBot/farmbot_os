defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor
  alias Farmbot.Sync.Database

  def init(%{target: target, compat_version: compat_version, version: version})
  do
    children = [
      # handles communications between bot and arduino
      supervisor(Farmbot.Serial.Supervisor, [], restart: :permanent),

      # Handles tracking of various parts of the bots state.
      supervisor(Farmbot.BotState.Supervisor,
        [%{target: target, compat_version: compat_version, version: version}],
      restart: :permanent),

      # Handles Farmbot scheduler stuff.
      worker(Farmbot.Scheduler, [], restart: :permanent),

      # Handles the passing of messages from one part of the system to another.
      supervisor(Farmbot.Transport.Supervisor, [], restart: :permanent),
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start(_, [args]) do
    Logger.debug ">> is starting up."
    Amnesia.start
    Database.create! Keyword.put([], :memory, [node])
    Database.wait(15_000)
    Supervisor.start_link(__MODULE__, args, name: Farmbot.Supervisor)
  end
end
