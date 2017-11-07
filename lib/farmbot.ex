defmodule Farmbot do
  @moduledoc """
  Supervises the individual modules that make up the Farmbot Application.
  This is the entry point of the application.

  Here is kind of how the tree works.
      + `Farmbot` - the Entry point of the app.
      |
      +---> + `Farmbot.System.Supervisor`    - The `init` system.
      |
      +---> + `Farmbot.Bootstrap.Supervisor` - Bootstraps into the main app.
            |
            +---> +` Farmbot.BotState.Superviror` - The main application.
                  |
                  +---> `BotState`               - Unions the next 5 modules.
                  |
                  +---> `InformationalSettings`  - Externally imutable settings.
                  |
                  +---> `Configuration`          - Externally mutable settings.
                  |
                  +---> `LocationData`           - Where the bot is in space.
                  |
                  +---> `McuParams`              - mutable hardware configuration.
                  |
                  +---> `ProcessInfo`            - Information about running processes on the bot.
                  |
                  +---> `Transport.Supervisor`   - Consumes the bot's state and talks to the rest of the world.
                  |
                  +---> `Firmware.Supervisor`    - Communicates with the `arduino-firmware`.
  """

  require Farmbot.Logger
  require Logger
  use Supervisor

  @version Mix.Project.config()[:version]
  @commit Mix.Project.config()[:commit]

  @doc """
  Entry Point to Farmbot
  """
  def start(type, start_opts)

  def start(_, _start_opts) do
    case Supervisor.start_link(__MODULE__, [], [name: __MODULE__]) do
      {:ok, pid} -> {:ok, pid}
      error ->
        IO.puts "Failed to boot Farmbot: #{inspect error}"
        Farmbot.System.factory_reset(error)
        exit(error)
    end
  end

  def init(args) do
    children = [
      supervisor(Farmbot.Logger.Supervisor, []),
      supervisor(Farmbot.System.Supervisor, []),
      supervisor(Farmbot.Bootstrap.Supervisor, [])
    ]

    Farmbot.Logger.info(1, "Booting Farmbot OS version: #{@version} - #{@commit}")
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
