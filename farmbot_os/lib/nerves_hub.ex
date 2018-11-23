defmodule Farmbot.System.NervesHub do
  @moduledoc """
  Wrapper for NervesHub that can support both host and target environments.

  Some things can be configured via Mix.Config:

      config :farmfarmbot_osbot, Farmbot.System.NervesHub, [
        farmbot_nerves_hub_handler: SomeModule,
        app_env: "application:some_other_tag",
        extra_tags: ["some", "more", "tags"]
      ]

  ## On Target Devices
  FarmBotOS requires some weird behaviour. `:nerves_hub` should not be started
  with the rest of the application. Connecting should input serial, cert and key
  into NervesRuntimeKV, restart NervesRuntimeKV, then _finally_ start `:nerves_hub`.

  ## On host.
  Just return :ok to everything.
  """

  @handler Application.get_env(:farmbot, __MODULE__)[:farmbot_nerves_hub_handler]
  || Mix.raise("missing :farmbot_nerves_hub_handler module")

  @doc "Function to return a String serial number. "
  @callback serial_number() :: String.t()

  @doc "Connect to NervesHub."
  @callback connect() :: :ok | :error

  @doc "Burn the serial number into persistent storage."
  @callback provision(serial :: String.t) :: :ok | :error

  @doc "Burn the cert and key into persistent storage."
  @callback configure_certs(cert :: String.t(), key :: String.t()) :: :ok | :error

  @doc "Return the current confuration including serial, cert and key."
  @callback config() :: [String.t() | nil]

  @doc "Remove serial, cert, and key from persistent storage."
  @callback deconfigure() :: :ok | :error

  @doc "Should return a url to an update or nil."
  @callback check_update() :: String.t() | nil

  use GenServer
  require Farmbot.Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    {:ok, :not_configured, 0}
  end

  def terminate(reason, state) do
    Farmbot.Logger.warn 1, "NervesHub crash: #{inspect reason} when in state: #{inspect state}"
  end

  def handle_info(:timeout, :not_configured) do
    channel = case Farmbot.Project.branch() do
      "master" -> "channel:stable"
      "beta" -> "channel:beta"
      "staging" -> "channel:staging"
      branch -> "channel:#{branch}"
    end

    app_config = Application.get_env(:farmbot, __MODULE__, [])

    "application:" <> _ = app_env = app_config[:app_env] || "application:#{Farmbot.Project.env()}"
    extra_tags = app_config[:extra_tags] || []

    if nil in get_config() do
      Farmbot.Logger.debug 1, "Doing initial NervesHub provision."
      :ok = deconfigure()
      :ok = provision()
      case configure([app_env, channel] ++ extra_tags) do
        {:ok, _provisioning} ->
          connect()
          {:noreply, :configured}
        {:error, reason} ->
          Farmbot.Logger.error 3, "NervesHub provision failed: #{inspect reason}"
          {:noreply, :not_configured, 10_000}
      end
    # nil is not in config.
    # This means NervesHub has already been provisioned.
    else
      connect()
      {:noreply, :configured}
    end
  end

  def get_config do
    @handler.config()
  end

  def connect do
    Farmbot.Logger.debug 1, "Connecting to NervesHub"
    @handler.connect()
  end

  # Returns the current serial number.
  def serial do
    @handler.serial_number()
  end

  # Sets Serial number in environment.
  def provision do
    Farmbot.Logger.debug 1, "Provisioning NervesHub"
    :ok = @handler.provision(serial())
  end

  # Creates a device in NervesHub
  # or updates it if one exists.
  def configure(tags) when is_list(tags) do
    Farmbot.Logger.debug 1, "Configuring NervesHub: #{inspect tags}"
    payload = %{
      serial_number: serial(),
      tags: tags
    } |> Farmbot.JSON.encode!()
    Farmbot.HTTP.post("/api/device_cert", payload)
  end

  # Message comes over AMQP.
  def configure_certs("-----BEGIN CERTIFICATE-----" <> _ = cert,
                      "-----BEGIN EC PRIVATE KEY-----" <> _ = key) do
    Farmbot.Logger.debug 1, "Configuring certs for NervesHub."
    :ok = @handler.configure_certs(cert, key)
    :ok
  end

  def deconfigure do
    Farmbot.Logger.debug 1, "Deconfiguring NervesHub"
    :ok = @handler.deconfigure()
    :ok
  end

  def check_update do
    Farmbot.Logger.debug 1, "Check update NervesHub"
    @handler.check_update()
  end
end
