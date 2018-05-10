defmodule Farmbot.Target.Bootstrap.Configurator do
  @moduledoc """
  This init module is used to bring up initial configuration.
  If it can't find a configuration it will bring up a captive portal for a device to connect to.
  """

  @behaviour Farmbot.System.Init
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage

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
    Logger.busy(3, "Configuring Farmbot.")
    supervisor = Supervisor.start_link(__MODULE__, [self()], opts)

    case supervisor do
      {:ok, pid} ->
        wait(pid)

      :ignore ->
        :ignore
    end
  end

  defp wait(pid) do
    if Process.alive?(pid) do
      Process.sleep(10)
      wait(pid)
    else
      :ignore
    end
  end

  def init(_) do
    first_boot? = ConfigStorage.get_config_value(:bool, "settings", "first_boot")
    if first_boot? do
      Logger.info(3, "Building new configuration.")
      import Supervisor.Spec
      :ets.new(:session, [:named_table, :public, read_concurrency: true])
      Farmbot.System.GPIO.Leds.led_status_err()
      alias Farmbot.Target.Bootstrap.Configurator
      ConfigStorage.destroy_all_network_configs()
      children = [
        {Plug.Adapters.Cowboy, scheme: :http, plug: Configurator.Router, options: [port: 80, acceptors: 1]},
        worker(Configurator.CaptivePortal, [])
      ]

      opts = [strategy: :one_for_one]
      Supervisor.init(children, opts)
    else
      :ignore
    end
  end

  def stop(supervisor, status) do
    Supervisor.stop(supervisor, :normal)
    status
  end
end
