defmodule  Farmbot.Bootstrap.Configurator do
  @moduledoc """
  This init module is used to bring up initial configuration.
  If it can't find a configuration it will bring up a captive portal for a device to connect to.
  """

  @behaviour Farmbot.System.Init
  @data_path Application.get_env(:farmbot, :data_path) || Mix.raise "Unconfigured data path."
  require Logger

  @doc """
  This particular init module should block until all settings have been validated.
  It handles things such as:
  * Initial flashing of the firmware.
  * Initial configuration of network settings.
  * Initial configuration of farmbot web app settings.

  When finished will return `:ignore` if all went well, or
  `{:error, reason}` if there were errors. This will cause a factory
  reset and the user will need to configureate again.
  """
  def start_link(_, opts) do
    Logger.info "Configuring Farmbot."
    sup = Supervisor.start_link(__MODULE__, [self()], opts)
    # case supervisor do
    #   {:ok, pid} ->
    #     receive do
    #       :ok -> stop(pid, :ignore)
    #       {:error, _reason} = err -> stop(pid, err)
    #     end
    #   :ignore -> :ignore
    # end
  end

  def init(cb) do
    file = Path.join(@data_path, "config.json")
    Logger.info "Loading config file: #{file}"
    case File.read(file) do
      {:ok, _config} ->
        Logger.info "Loading existing config."
        :ignore
      _ ->
        Logger.info "Building new config."
        import Supervisor.Spec
        :ets.new(:session, [:named_table, :public, read_concurrency: true])
        children = [
          Plug.Adapters.Cowboy.child_spec(:http, Farmbot.Bootstrap.Configurator.Router, [], [port: 4001])
        ]
        opts = [strategy: :one_for_one]
        supervise(children, opts)
    end
  end

  defp stop(supervisor, status) do
    Supervisor.stop(supervisor, :normal)
    status
  end
end
