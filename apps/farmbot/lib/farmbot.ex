defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor
  alias Farmbot.Sync.Database

  @spec init(map) :: [{:ok, pid}]
  def init(%{target: target,
             compat_version: compat_version,
             version: version,
             commit: commit})
  do
    children = [
      supervisor(Farmbot.Configurator, [], restart: :permanent),
      # Generic counter.
      worker(Counter, [], restart: :permanent),
      # The worker for diffing db entries.
      worker(Farmbot.Sync.Database.Diff, [], restart: :permanent),
      # Handles tracking of various parts of the bots state.
      supervisor(Farmbot.BotState.Supervisor,
        [%{target: target,
           compat_version: compat_version,
           version: version,
           commit: commit}], restart: :permanent),

      # Handles the passing of messages from one part of the system to another.
      supervisor(Farmbot.Transport.Supervisor, [], restart: :permanent),

      # Handles external scripts and what not
      supervisor(Farmware.Supervisor, [], restart: :permanent),

      # handles communications between bot and arduino
      supervisor(Farmbot.Serial.Supervisor, [], restart: :permanent),
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Starts the Farmbot Application
  """
  @spec start(atom, [any]) :: {:ok, pid}
  def start(_, [args]) do
    Logger.debug ">> init!"
    Logger.error "TEST"
    Amnesia.start
    Database.create! Keyword.put([], :memory, [node()])
    Database.wait(15_000)
    Supervisor.start_link(__MODULE__, args, name: Farmbot.Supervisor)
  end
end
