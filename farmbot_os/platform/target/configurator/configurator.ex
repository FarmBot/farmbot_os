defmodule Farmbot.Target.Bootstrap.Configurator do
  @moduledoc """
  This init module is used to bring up initial configuration.
  If it can't find a configuration it will bring up a captive portal for a device to connect to.
  """

  use Supervisor
  require Farmbot.Logger
  alias Farmbot.Config
  import Config, only: [get_config_value: 3, update_config_value: 4]
  alias Farmbot.Target.Bootstrap.Configurator

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
  def start_link(_) do
    Farmbot.Logger.busy(3, "Configuring Farmbot.")
    supervisor = Supervisor.start_link(__MODULE__, [self()], [name: __MODULE__])

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
    first_boot? = get_config_value(:bool, "settings", "first_boot")
    autoconfigure? = Nerves.Runtime.KV.get("farmbot_auto_configure") |> case do
      "" -> false
      other when is_binary(other) -> true
      _ -> false
    end


    if first_boot? do
      maybe_configurate(autoconfigure?)
    else
      :ignore
    end
  end

  def stop(supervisor, status) do
    Supervisor.stop(supervisor, :normal)
    status
  end

  defp maybe_configurate(false) do
    Farmbot.Logger.info(3, "Building new configuration.")
    update_config_value(:bool, "settings", "ignore_fbos_config", true)
    update_config_value(:bool, "settings", "ignore_fw_config", true)
    import Supervisor.Spec
    :ets.new(:session, [:named_table, :public, read_concurrency: true])
    Config.destroy_all_network_configs()
    children = [
      worker(Configurator.CaptivePortal, [], restart: :transient),
      {Plug.Adapters.Cowboy, scheme: :http, plug: Configurator.Router, options: [port: 80, acceptors: 1]}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  defp maybe_configurate(_) do
    ifname   = Nerves.Runtime.KV.get("farmbot_network_iface")
    ssid     = Nerves.Runtime.KV.get("farmbot_network_ssid")
    psk      = Nerves.Runtime.KV.get("farmbot_network_psk")
    email    = Nerves.Runtime.KV.get("farmbot_email")
    server   = Nerves.Runtime.KV.get("farmbot_server")
    password = Nerves.Runtime.KV.get("farmbot_password")
    Config.input_network_config!(%{
      name: ifname,
      ssid: ssid,
      security: "WPA-PSK", psk: psk,
      type: if(ssid, do: "wireless", else: "wired"),
      domain: nil,
      name_servers: nil,
      ipv4_method: "dhcp",
      ipv4_address: nil,
      ipv4_gateway: nil,
      ipv4_subnet_mask: nil
    })

    update_config_value(:string, "authorization", "email", email)
    update_config_value(:string, "authorization", "password", password)
    update_config_value(:string, "authorization", "server", server)
    update_config_value(:string, "authorization", "token", nil)
    :ignore
  end
end
