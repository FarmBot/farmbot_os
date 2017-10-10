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

  require Logger
  use Supervisor

  @version Mix.Project.config[:version]
  @commit  Mix.Project.config[:commit]

  @doc """
  Entry Point to Farmbot
  """
  def start(type, start_opts)
  def start(_, start_opts) do
    Logger.info ">> Booting Farmbot OS version: #{@version} - #{@commit}"
    name = Keyword.get(start_opts, :name, __MODULE__)
    case Supervisor.start_link(__MODULE__, [], [name: name]) do
      {:ok, pid}       -> {:ok, pid}
      error ->
        Logger.error "Uncaught startup error!"
        Farmbot.System.factory_reset(error)
        exit(error)
    end
  end

  def init(args) do
    children = [
      supervisor(Farmbot.System.Supervisor,      [args, [name: Farmbot.System.Supervisor    ]]),
      supervisor(Farmbot.Bootstrap.Supervisor,   [args, [name: Farmbot.Bootstrap.Supervisor ]]),
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
