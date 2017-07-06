defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor
  alias Farmbot.System.Supervisor, as: FBSYS

  @version Mix.Project.config[:version]
  @commit Mix.Project.config[:commit]

  @doc """
    Entry Point to Farmbot
  """
  def start(type, args)
  def start(_, _args) do
    Logger.info ">> Booting Farmbot OS version: #{@version} - #{@commit}"
    :ok = setup_nerves_fw()
    Supervisor.start_link(__MODULE__, [], name: Farmbot.Supervisor)
  end

  def init(_args) do
    context = Farmbot.Context.new()
    # ctx_tracker = %Farmbot.Context.Tracker{pid: Farmbot.Context.Tracker}
    children = [
      worker(Farmbot.DebugLog, []),
      supervisor(Registry, [:duplicate,  Farmbot.Registry]),
      supervisor(FBSYS,                   [context, [name: FBSYS]]),
      worker(Farmbot.Auth,                [context, [name: Farmbot.Auth]]),
      worker(Farmbot.FactoryResetWatcher, [context, context.auth, []]),
      worker(Farmbot.HTTP,                [context, [name: Farmbot.HTTP]]),
      worker(Farmbot.Database,            [context, [name: Farmbot.Database]]),
      supervisor(Farmbot.BotState.Supervisor,  [context, [name: Farmbot.BotState.Supervisor  ]]),
      supervisor(Farmbot.FarmEvent.Supervisor, [context, [name: Farmbot.FarmEvent.Supervisor ]]),
      supervisor(Farmbot.Transport.Supervisor, [context, [name: Farmbot.Transport.Supervisor ]]),
      worker(Farmbot.ImageWatcher,             [context, [name: Farmbot.ImageWatcher         ]]),
      supervisor(Farmbot.Serial.Supervisor,    [context, [name: Farmbot.Serial.Supervisor    ]]),
      supervisor(Farmbot.Configurator, []),
      supervisor(Farmbot.Farmware.Supervisor,  [context, [name: Farmbot.Farmware.Supervisor]])
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
