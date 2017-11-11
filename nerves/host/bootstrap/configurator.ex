defmodule Farmbot.Host.Bootstrap.Configurator do
  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  defp start_node() do
    case Node.start(:"farmbot-host@127.0.0.1") do
      {:ok, _} -> :ok
      _ -> :ok
    end
  end

  def init(_) do
    start_node()
    # Get out authorization data out of the environment.
    # for host environment this will be configured at compile time.
    # for target environment it will be configured by `configurator`.
    email = Application.get_env(:farmbot, :authorization)[:email] || raise error("email")
    pass = Application.get_env(:farmbot, :authorization)[:password] || raise error("password")
    server = Application.get_env(:farmbot, :authorization)[:server] || raise error("server")
    ConfigStorage.update_config_value(:string, "authorization", "email", email)
    ConfigStorage.update_config_value(:string, "authorization", "password", pass)
    ConfigStorage.update_config_value(:string, "authorization", "server", server)
    ConfigStorage.update_config_value(:string, "authorization", "token", nil)
    :ignore
  end

  defp error(_field) do
    """
    Your environment is not properly configured! You will need to follow the
    directions in `config/host/auth_secret_template.exs` before continuing.
    """
  end
end
