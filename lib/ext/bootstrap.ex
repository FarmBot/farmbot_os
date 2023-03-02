defmodule FarmbotOS.Bootstrap do
  @moduledoc """
  Task responsible for using
  a token, secret, or password for logging into an account
  """

  use GenServer
  require FarmbotOS.Logger
  require Logger
  alias FarmbotOS.{Bootstrap, Bootstrap.Authorization}
  import FarmbotOS.Config, only: [update_config_value: 4, get_config_value: 3]

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    {:ok, nil, 0}
  end

  @impl GenServer
  def handle_info(:timeout, nil) do
    email = get_config_value(:string, "authorization", "email")
    server = get_config_value(:string, "authorization", "server")
    password = get_config_value(:string, "authorization", "password")
    secret = get_config_value(:string, "authorization", "secret")
    try_auth(email, server, password, secret)
  end

  # state machine implementation
  @doc false
  def try_auth(nil, _server, _password, _secret) do
    FarmbotOS.Time.no_reply(nil, 5000)
  end

  def try_auth(_email, nil, _password, _secret) do
    FarmbotOS.Time.no_reply(nil, 5000)
  end

  def try_auth(email, server, nil, secret) when is_binary(secret) do
    Logger.debug("using secret to auth")

    with {:ok, tkn} <-
           Authorization.authorize_with_secret(email, secret, server),
         _ <- update_config_value(:string, "authorization", "token", tkn),
         {:ok, pid} <- Supervisor.start_child(FarmbotOS, Bootstrap.Supervisor) do
      {:noreply, pid}
    else
      _ -> FarmbotOS.Time.no_reply(nil, 5000)
    end
  end

  def try_auth(email, server, password, _secret) do
    with {:ok, tkn} <-
           Authorization.authorize_with_password(email, password, server),
         _ <- update_config_value(:string, "authorization", "token", tkn),
         {:ok, pid} <- Supervisor.start_child(FarmbotOS, Bootstrap.Supervisor) do
      {:noreply, pid}
    else
      # Changing the error message on the API
      # will break this handler. Hmm...
      {:error, "Bad email or password."} ->
        msg = "Password auth failed! Check again and reconfigurate."
        Logger.error(msg)
        FarmbotOS.Logger.debug(3, msg)

        FarmbotOS.System.factory_reset("""
        FarmBot successfully connected to the web app
        servers at #{server} but was not able to login to
        the #{email} account. If you have registered an account with this
        email, please try again and use the
        eye icon to double check you have typed the
        password correctly.
        """)

        FarmbotOS.Time.no_reply(nil, 5000)

      er ->
        msg = "Bootstrap try_auth: #{inspect(er)} "
        Logger.error(msg)
        FarmbotOS.Logger.debug(3, msg)
        FarmbotOS.Time.no_reply(nil, 5000)
    end
  end

  def reauth do
    email = get_config_value(:string, "authorization", "email")
    server = get_config_value(:string, "authorization", "server")
    secret = get_config_value(:string, "authorization", "secret")

    with {:ok, tkn} <-
           Authorization.authorize_with_secret(email, secret, server),
         _ <- update_config_value(:string, "authorization", "token", tkn) do
      {:ok, tkn}
    end
  end
end
