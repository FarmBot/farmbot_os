defmodule FarmbotOS.Configurator.DataLayer do
  @moduledoc """
  intermediate layer for stubbing configuration data
  """
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
