defmodule Farmbot.Host.InputCredentials do
  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    # require IEx; IEx.pry
    # Get out authorization data out of the environment.
    # for host environment this will be configured at compile time.
    # for target environment it will be configured by `configurator`.
    email  = Application.get_env(:farmbot, :authorization)[:email   ] || raise error("email")
    pass   = Application.get_env(:farmbot, :authorization)[:password] || raise error("password")
    server = Application.get_env(:farmbot, :authorization)[:server  ] || raise error("server")
    ConfigStorage.update_config_value(:string, "authorization", "email",    email)
    ConfigStorage.update_config_value(:string, "authorization", "password", pass)
    ConfigStorage.update_config_value(:string, "authorization", "server",   server)
    ConfigStorage.update_config_value(:string, "authorization", "token",    nil)
    # require IEx; IEx.pry
    # Process.sleep(1000)
    :ignore
  end

  defp error(field) do
    """
    Your environment is not properly configured! You will need to follow the
    directions in `config/host/auth_secret_template.exs` before continuing.
    """
  end
end
