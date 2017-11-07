defmodule Farmbot.Bootstrap.Supervisor do
  @moduledoc """
  Bootstraps the application.

  It is expected that there is authorization credentials in the application's
  environment by this point. This can be configured via a `Farmbot.Init` module.

  For example:

  # config.exs
      use Mix.Config

      config :farmbot, :init, [
        Farmbot.Configurator
      ]

      config :farmbot, :behaviour,
        authorization: Farmbot.Configurator

  # farmbot_configurator.ex

      defmodule Farmbot.Configurator do
        @moduledoc false
        @behaviour Farmbot.System.Init
        @behaviour Farmbot.Bootstrap.Authorization

        # Callback for Farmbot.System.Init.
        # This can return {:ok, pid} if it should be a supervisor.
        def start_link(_args, _opts) do
          creds = [
            email: "some_user@some_server.org",
            password: "some_secret_password_dont_actually_store_in_plain_text",
            server:   "https://my.farmbot.io"
          ]
          Application.put_env(:farmbot, :behaviour, creds)
          :ignore
        end

        # Callback for Farmbot.Bootstrap.Authorization.
        # Should return `{:ok, token}` where `token` is a binary jwt, or
        # {:error, reason} reason can be anything, but a binary is easiest to
        # Parse.
        def authorize(email, password, server) do
          # some intense http stuff or whatever.
          {:ok, token}
        end
      end

  This will cause the `creds` to be stored in the application's environment.
  This moduld then will try to use the configured module to `authorize`.

  If either of these things error, the bot try to factory reset
  """

  use Supervisor
  alias Farmbot.Bootstrap.Authorization, as: Auth
  alias Farmbot.System.ConfigStorage
  use Farmbot.Logger

  error_msg = """
  Please configure an authorization module!
  for example:
      config: :farmbot, :behaviour, [
        authorization: Farmbot.Bootstrap.Authorization
      ]
  """

  @auth_task Application.get_env(:farmbot, :behaviour)[:authorization] || Mix.raise(error_msg)

  @doc "Start Bootstrap services."
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    # try to find the creds.
    case get_creds() do
      # do the actual supervisor init if we have creds. This may still fail.
      {email, pass, server} ->
        actual_init(email, pass, server)

      # This will cause a factory reset.
      {:error, reason} ->
        {:error, reason}
    end
  end

  @typedoc "Authorization credentials."
  @type auth :: {Auth.email(), Auth.password(), Auth.server()}

  @spec get_creds() :: auth | {:error, term}
  defp get_creds do
    try do
      email =
        ConfigStorage.get_config_value(:string, "authorization", "email") ||
          raise "No email provided."

      pass =
        ConfigStorage.get_config_value(:string, "authorization", "password") ||
          raise "No password provided."

      server =
        ConfigStorage.get_config_value(:string, "authorization", "server") ||
          raise "No server provided."

      {email, pass, server}
    rescue
      e in RuntimeError -> {:error, Exception.message(e)}
      e -> reraise(e, System.stacktrace())
    end
  end

  defp actual_init(email, pass, server) do
    Logger.busy(2, "Beginning authorization: #{@auth_task} - #{email} - #{server}")
    # get a token
    case @auth_task.authorize(email, pass, server) do
      {:ok, token} ->
        Logger.info(2, "Successful authorization: #{@auth_task} - #{email} - #{server}")
        ConfigStorage.update_config_value(:bool, "settings", "first_boot", false)
        ConfigStorage.update_config_value(:string, "authorization", "token", token)
        ConfigStorage.update_config_value(:string, "authorization", "last_shutdown_reason", nil)

        children = [
          worker(Farmbot.Bootstrap.AuthTask, []),
          supervisor(Farmbot.BotState.Supervisor, []),
          supervisor(Farmbot.HTTP.Supervisor,     []),
          supervisor(Farmbot.Repo.Supervisor,     []),
          supervisor(Farmbot.Farmware.Supervisor, [])
        ]

        opts = [strategy: :one_for_all]
        supervise(children, opts)

      # I don't actually _have_ to factory reset here. It would get detected ad
      # an application start fail and we would factory_reset from there,
      # the error message is just way more useful here.
      {:error, reason} ->
        Farmbot.System.factory_reset(reason)
        :ignore

      # If we got invalid json, just try again.
      # FIXME(Connor) Why does this happen?
      {:error, :invalid, _} ->
        actual_init(email, pass, server)
    end
  end
end
