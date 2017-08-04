defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor
  alias Farmbot.System.Supervisor, as: FBSYS

  @version Mix.Project.config[:version]
  @commit  Mix.Project.config[:commit]

  @doc """
  Entry Point to Farmbot
  """
  def start(type, args)
  def start(_, args) do
    Logger.info ">> Booting Farmbot OS version: #{@version} - #{@commit}"
    case Supervisor.start_link(__MODULE__, args, name: Farmbot) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> Farmbot.System.factory_reset(reason)
    end
  end

  def init(args) do
    children = [
      worker(Farmbot.DebugLog, []),
      supervisor(Registry, [:duplicate,  Farmbot.Registry]),

      supervisor(Farmbot.System.Supervisor,    [args, [name: Farmbot.System.Supervisor    ]]),
      supervisor(Farmbot.HTTP.Supervisor,      [args, [name: Farmbot.HTTP.Supervisor      ]]),
      supervisor(Farmbot.BotState.Supervisor,  [args, [name: Farmbot.BotState.Supervisor  ]]),
      supervisor(Farmbot.FarmEvent.Supervisor, [args, [name: Farmbot.FarmEvent.Supervisor ]]), # amybe make this a child of the database?
      supervisor(Farmbot.Transport.Supervisor, [args, [name: Farmbot.Transport.Supervisor ]]),
      supervisor(Farmbot.Serial.Supervisor,    [args, [name: Farmbot.Serial.Supervisor    ]]),
      supervisor(Farmbot.Farmware.Supervisor,  [args, [name: Farmbot.Farmware.Supervisor  ]]),
      worker(Farmbot.ImageWatcher,             [args, [name: Farmbot.ImageWatcher         ]]), # this may need to move too.
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  # This has to be at runtime because you cant access your own apps
  # priv dir during Mix.Config.
  if Mix.env == :prod do

    defp setup_nerves_fw do
      Logger.info ">> Setting up firmware signing!"
      file = "#{:code.priv_dir(:farmbot)}/fwup-key.pub"
      Application.put_env(:nerves_firmware, :pub_key_path, file)
      if File.exists?(file), do: :ok, else: {:error, :no_pub_file}
    end
  else

    defp setup_nerves_fw do
      Logger.info ">> Disabling firmware signing!"
      Application.put_env(:nerves_firmware, :pub_key_path, nil)
      :ok
    end

  end
end
