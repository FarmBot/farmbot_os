defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor

  @version Mix.Project.config[:version]
  @commit  Mix.Project.config[:commit]

  @doc """
  Entry Point to Farmbot
  """
  def start(type, args)
  def start(_, args) do
    Logger.info ">> Booting Farmbot OS version: #{@version} - #{@commit}"
    case Supervisor.start_link(__MODULE__, args, [name: Farmbot]) do
      {:ok, pid} -> {:ok, pid}
      # {:error, reason} -> Farmbot.System.factory_reset(reason)
    end
  end

  def init(args) do
    children = [
      supervisor(Registry, [:duplicate,  Farmbot.Registry]),
      supervisor(Farmbot.System.Supervisor,    [args, [name: Farmbot.System.Supervisor    ]]),
      # supervisor(Farmbot.HTTP.Supervisor,      [args, [name: Farmbot.HTTP.Supervisor      ]]),
      # supervisor(Farmbot.BotState.Supervisor,  [args, [name: Farmbot.BotState.Supervisor  ]]),
      # supervisor(Farmbot.Transport.Supervisor, [args, [name: Farmbot.Transport.Supervisor ]]), # Can this be a child of the bot's state maybe?
      # supervisor(Farmbot.FarmEvent.Supervisor, [args, [name: Farmbot.FarmEvent.Supervisor ]]), # maybe make this a child of the database?
      # supervisor(Farmbot.Serial.Supervisor,    [args, [name: Farmbot.Serial.Supervisor    ]]),
      # supervisor(Farmbot.Farmware.Supervisor,  [args, [name: Farmbot.Farmware.Supervisor  ]]),
      # worker(Farmbot.ImageWatcher,             [args, [name: Farmbot.ImageWatcher         ]]), # this may need to move too.
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
