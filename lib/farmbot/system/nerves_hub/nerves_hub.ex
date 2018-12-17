defmodule Farmbot.System.NervesHub do
  @moduledoc """
  Wrapper for NervesHub that can support both host and target environments.

  Some things can be configured via Mix.Config:

      config :farmbot, Farmbot.System.NervesHub, [
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

  @handler Application.get_env(:farmbot, :behaviour)[:nerves_hub_handler]
  || Mix.raise("missing :nerves_hub_handler module")

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

  @doc "Should return the uuid of the running firmware"
  @callback uuid :: String.t()

  use GenServer
  use Farmbot.Logger

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    send self(), :configure
    {:ok, :not_configured}
  end

  def terminate(reason, state) do
    Logger.warn 1, "OTA Server crash: #{inspect reason} when in state: #{inspect state}"
  end

  def handle_info(:configure, :not_configured) do
    channel = case Farmbot.Project.branch() do
      "master" -> "channel:stable"
      "beta" -> "channel:beta"
      "staging" -> "channel:staging"
      branch -> "channel:#{branch}"
    end

    if Process.whereis(Farmbot.HTTP) do
      app_config = Application.get_env(:farmbot, __MODULE__, [])

      "application:" <> _ = app_env = app_config[:app_env] || "application:#{Farmbot.Project.env()}"
      extra_tags = app_config[:extra_tags] || []

      if nil in get_config() do
        Logger.info 1, "doing initial OTA configuration."
        :ok = deconfigure()
        :ok = provision()
        :ok = configure([app_env, channel] ++ extra_tags)
      else
        connect()
      end

      {:noreply, :configured}
    else
      Logger.debug 3, "FarmBot Server not configured yet. Waiting 10_000 ms to try OTA config again."
      Process.send_after(self(), :configure, 10_000)
      {:noreply, :not_configured}
    end
  end

  def get_config do
    @handler.config()
  end

  def connect do
    Logger.debug 1, "Connecting to OTA Server"
    @handler.connect()
  end

  # Returns the current serial number.
  def serial do
    @handler.serial_number()
  end

  # Sets Serial number in environment.
  def provision do
    Logger.debug 1, "Provisioning OTA Server"
    :ok = @handler.provision(serial())
  end

  # Creates a device in NervesHub
  # or updates it if one exists.
  def configure(tags) when is_list(tags) do
    Logger.debug 1, "Configuring OTA Server: #{inspect tags}"
    payload = %{
      serial_number: serial(),
      tags: tags
    } |> Farmbot.JSON.encode!()
    _ = Farmbot.HTTP.post!("/api/device_cert", payload)
    :ok
  end

  # Message comes over AMQP.
  def configure_certs("-----BEGIN CERTIFICATE-----" <> _ = cert,
                      "-----BEGIN EC PRIVATE KEY-----" <> _ = key) do
    Logger.debug 1, "Configuring certs for OTA Server."
    :ok = @handler.configure_certs(cert, key)
    :ok
  end

  def deconfigure do
    Logger.debug 1, "Deconfiguring OTA Server"
    :ok = @handler.deconfigure()
    :ok
  end

  def check_update do
    Logger.debug 1, "Check update OTA Server"
    @handler.check_update()
  end

  def uuid do
    @handler.uuid()
  end
end
