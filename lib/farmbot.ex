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
      {:error, reason} -> Farmbot.System.factory_reset(reason)
    end
  end

  def init(args) do
    children = [
      supervisor(Farmbot.System.Supervisor,      [args, [name: Farmbot.System.Supervisor    ]]),
      supervisor(Farmbot.Bootstrap.Supervisor,   [args, [name: Farmbot.Bootstrap.Supervisor ]]),
      # supervisor(Farmbot.FarmEvent.Supervisor,   [args, [name: Farmbot.FarmEvent.Supervisor ]]),
      # supervisor(Farmbot.Firmware.Supervisor,    [args, [name: Farmbot.Firmware.Supervisor  ]]),
      # supervisor(Farmbot.Farmware.Supervisor,    [args, [name: Farmbot.Farmware.Supervisor  ]]),

      ## LEGACY
      # supervisor(Farmbot.Transport.Supervisor, [args, [name: Farmbot.Transport.Supervisor ]]),
      # supervisor(Farmbot.Serial.Supervisor,    [args, [name: Farmbot.Serial.Supervisor    ]]),
      # worker(Farmbot.ImageWatcher,             [args, [name: Farmbot.ImageWatcher         ]]), # this may need to move too.
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
