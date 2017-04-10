defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor
  alias Farmbot.Sync.Database
  alias Farmbot.System.Supervisor, as: FBSYS

  @doc """
    Entry Point to Farmbot
  """
  def start(type, args)
  def start(_, _args) do
    Logger.info ">> init!"
    Amnesia.start
    Database.create! Keyword.put([], :memory, [node()])
    Database.wait(15_000)
    Supervisor.start_link(__MODULE__, [], name: Farmbot.Supervisor)
  end

  def init(_args) do
    children = [
      # Generic counter.
      worker(Counter, [], restart: :permanent),
      # System specifics.
      supervisor(FBSYS, [], restart: :permanent),
      # Auth services.
      worker(Farmbot.Auth, [], restart: :permanent),
      # Web app.
      supervisor(Farmbot.Configurator, [], restart: :permanent),
      # The worker for diffing db entries.
      worker(Farmbot.Sync.Supervisor, [], restart: :permanent),
      # Handles tracking of various parts of the bots state.
      supervisor(Farmbot.BotState.Supervisor, [], restart: :permanent),
      # Handles FarmEvents.
      supervisor(Farmbot.FarmEvent.Supervisor, [], restart: :permanent),
      # Handles the passing of messages from one part of the system to another.
      supervisor(Farmbot.Transport.Supervisor, [], restart: :permanent),
      # Handles external scripts and what not.
      supervisor(Farmware.Supervisor, [], restart: :permanent),
      # handles communications between bot and arduino.
      supervisor(Farmbot.Serial.Supervisor, [], restart: :permanent),
      # Watches the images directory and uploads them.
      worker(Farmbot.ImageWatcher, [], restart: :permanent)
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
