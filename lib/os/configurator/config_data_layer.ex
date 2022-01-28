defmodule FarmbotOS.Configurator.ConfigDataLayer do
  @moduledoc """
  implementation of Configurator.DataLayer responsible for
  gathering and storing data Via Ecto.
  """

  @behaviour FarmbotOS.Configurator.DataLayer
  require FarmbotOS.Logger
  alias FarmbotOS.Config
  alias FarmbotOS.FileSystem

  @impl FarmbotOS.Configurator.DataLayer
  def save_config(%{
        "ifname" => ifname,
        "iftype" => iftype,
        "net_config_dns_name" => net_config_dns_name,
        "net_config_ntp1" => net_config_ntp1,
        "net_config_ntp2" => net_config_ntp2,
        "net_config_ssid" => net_config_ssid,
        "net_config_security" => net_config_security,
        "net_config_psk" => net_config_psk,
        "net_config_identity" => net_config_identity,
        "net_config_password" => net_config_password,
        "net_config_domain" => net_config_domain,
        "net_config_name_servers" => net_config_name_servers,
        "net_config_ipv4_method" => net_config_ipv4_method,
        "net_config_ipv4_address" => net_config_ipv4_address,
        "net_config_ipv4_gateway" => net_config_ipv4_gateway,
        "net_config_ipv4_subnet_mask" => net_config_ipv4_subnet_mask,
        "net_config_reg_domain" => net_config_reg_domain,
        "auth_config_email" => auth_config_email,
        "auth_config_password" => auth_config_password,
        "auth_config_server" => auth_config_server
      }) do
    network_params = %{
      name: ifname,
      type: iftype,
      ssid: net_config_ssid,
      psk: net_config_psk,
      security: net_config_security,
      identity: net_config_identity,
      password: net_config_password,
      ipv4_method: net_config_ipv4_method,
      ipv4_address: net_config_ipv4_address,
      ipv4_gateway: net_config_ipv4_gateway,
      ipv4_subnet_mask: net_config_ipv4_subnet_mask,
      domain: net_config_domain,
      name_servers: net_config_name_servers,
      regulatory_domain: net_config_reg_domain
    }

    # Network settings
    _ = Config.input_network_config!(network_params)

    # Runtime network configuration
    _ =
      Config.update_config_value(
        :string,
        "settings",
        "default_ntp_server_1",
        net_config_ntp1
      )

    _ =
      Config.update_config_value(
        :string,
        "settings",
        "default_ntp_server_2",
        net_config_ntp2
      )

    _ =
      Config.update_config_value(
        :string,
        "settings",
        "default_dns_name",
        net_config_dns_name
      )

    # Farmbot specific auth data
    _ = Config.update_config_value(:string, "authorization", "secret", nil)

    _ =
      Config.update_config_value(
        :string,
        "authorization",
        "email",
        auth_config_email
      )

    _ =
      Config.update_config_value(
        :string,
        "authorization",
        "password",
        auth_config_password
      )

    _ =
      Config.update_config_value(
        :string,
        "authorization",
        "server",
        auth_config_server
      )

    :ok
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_last_reset_reason() do
    file_path = Path.join(FileSystem.data_path(), "last_shutdown_reason")

    case File.read(file_path) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_email() do
    Config.get_config_value(:string, "authorization", "email")
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_password() do
    Config.get_config_value(:string, "authorization", "password")
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_server() do
    Config.get_config_value(:string, "authorization", "server")
  end
end
