defmodule FarmbotOS.Configurator.DataLayer do
  @moduledoc """
  intermediate layer for stubbing configuration data
  """

  # "net_config_dns_name" => String.t()
  # "net_config_ntp1" => String.t()
  # "net_config_ntp2" => String.t()
  # "net_config_ssh_key" => String.t()
  # "net_config_ssid" => String.t()
  # "net_config_security" => String.t()
  # "net_config_psk" => String.t()
  # "net_config_identity" => String.t()
  # "net_config_password" => String.t()
  # "net_config_domain" => String.t()
  # "net_config_name_servers" => String.t()
  # "net_config_ipv4_method" => String.t()
  # "net_config_ipv4_address" => String.t()
  # "net_config_ipv4_gateway" => String.t()
  # "net_config_ipv4_subnet_mask" => String.t()
  # "net_config_reg_domain" => String.t()
  # "auth_config_email" => String.t()
  # "auth_config_password" => String.t()
  # "auth_config_server" => String.t()
  @type conf :: %{
          required(String.t()) => nil | String.t()
        }

  @doc "check if the most resent reboot was caused for an exceptional reason"
  @callback load_last_reset_reason() :: nil | String.t()

  @doc "load the email from the configuration store"
  @callback load_email() :: nil | String.t()

  @doc "load the password from the configuration store"
  @callback load_password() :: nil | String.t()

  @doc "load the server from the configuration store"
  @callback load_server() :: nil | String.t()

  @doc "save the configuration data to the configuration store"
  @callback save_config(conf) :: any()
end
