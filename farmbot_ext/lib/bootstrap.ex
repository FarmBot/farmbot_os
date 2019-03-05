defmodule FarmbotExt.Bootstrap do
  use GenServer

  require Logger
  alias FarmbotExt.{Bootstrap, Bootstrap.Authorization}
  import FarmbotCore.Config, only: [update_config_value: 4, get_config_value: 3]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:ok, nil, 0}
  end

  def handle_info(:timeout, nil) do
    email = get_config_value(:string, "authorization", "email")
    server = get_config_value(:string, "authorization", "server")
    password = get_config_value(:string, "authorization", "password")
    secret = get_config_value(:string, "authorization", "secret")
    try_auth(email, server, password, secret)
  end

  def try_auth(nil, _server, _password, _secret) do
    {:noreply, nil, 5000}
  end

  def try_auth(_email, nil, _password, _secret) do
    {:noreply, nil, 5000}
  end

  def try_auth(email, server, nil, secret) when is_binary(secret) do
    Logger.debug("using secret to auth")

    with {:ok, tkn} <- Authorization.authorize_with_secret(email, secret, server),
         _ <- update_config_value(:string, "authorization", "token", tkn),
         {:ok, pid} <- Supervisor.start_child(FarmbotExt, Bootstrap.Supervisor) do
      {:noreply, pid}
    else
      _ -> {:noreply, nil, 5000}
    end
  end

  # TODO(Connor) - drop password and save secret here somehow.
  def try_auth(email, server, password, _secret) do
    Logger.debug("using password to auth")

    with {:ok, tkn} <- Authorization.authorize_with_password(email, password, server),
         _ <- update_config_value(:string, "authorization", "token", tkn),
         {:ok, pid} <- Supervisor.start_child(FarmbotExt, Bootstrap.Supervisor) do
      {:noreply, pid}
    else
      er ->
        Logger.error("password auth failed: #{inspect(er)} ")
        {:noreply, nil, 5000}
    end
  end
end
