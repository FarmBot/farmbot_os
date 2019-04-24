defmodule FarmbotOS.Platform.Target.NervesHubClient do
  @moduledoc """
  NervesHub.Client implementation.

  This should be one of the very first processes to be started. 
  Because it is started so early, it has to check for things that
  might not be available in the environment. Environment is checked
  in this order:
  * token
  * email
  * amqp access (relies on network + NTP)
  * `DeviceCert`
  * nerves_hub `cert` + `key`

  ## State flow

  The basic flow of state changes follows that path as well.
  1) check for nerves_hub `cert` and `key`
    1a) if `cert` and `key` are available goto 4.
    1b) if not, goto 2.
  2) check for Farmbot `DeviceCert`.
    2a) if available update tags. goto 3.
    2b) if not avialable, create. goto 3.
  3) Wait for Farmbot API to dispatch nerves_hub `cert` and `key`.
  4) When `cert` and `key` is available, try to connect to `nerves_hub`.

  ## After connection

  While connected to NervesHub this process implements the
  `NervesHub.Client` behaviour. When an update becomes available from a
  NervesHub deployment, `update_available` will be called. This should
  check if the Farmbot settings allow for auto updating. If so, apply the
  update, if not wait for a CeleryScript request to update via `check_update`
  """

  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  alias FarmbotCore.Project
  alias FarmbotCore.{BotState, BotState.JobProgress.Percent}
  alias FarmbotCore.{Asset, Config, JSON}
  alias FarmbotExt.JWT
  require FarmbotCore.Logger
  require Logger

  alias FarmbotExt.AMQP.ConnectionWorker
  @behaviour NervesHub.Client

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt, :key, :cert, :is_applying_update, :firmware_url]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc "Returns the serial number of this device"
  def serial_number(:rpi0), do: serial_number("rpi")
  def serial_number(:rpi3), do: serial_number("rpi")

  def serial_number(plat) do
    :os.cmd(
      '/usr/bin/boardid -b uboot_env -u nerves_serial_number -b uboot_env -u serial_number -b #{
        plat
      }'
    )
    |> to_string()
    |> String.trim()
  end

  @doc "Returns the serial number of this device"
  def serial_number, do: serial_number(Project.target())

  @doc "Returns the uuid of the running firmware"
  def uuid, do: Nerves.Runtime.KV.get_active("nerves_fw_uuid")

  @doc "Loads the cert from storage"
  def load_cert, do: Nerves.Runtime.KV.get("nerves_hub_cert") |> filter_parens()

  @doc "Loads the key from storage"
  def load_key, do: Nerves.Runtime.KV.get("nerves_hub_key") |> filter_parens()

  @doc false
  def write_serial(serial_number) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_serial_number", serial_number)
    Nerves.Runtime.KV.UBootEnv.put("nerves_fw_serial_number", serial_number)
  end

  @doc false
  def write_cert(cert) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_cert", cert)
  end

  @doc false
  def write_key(key) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_key", key)
  end

  @impl NervesHub.Client
  def handle_error(error) do
    GenServer.cast(__MODULE__, {:handle_nerves_hub_error, error})
    :ok
  end

  @impl NervesHub.Client
  def handle_fwup_message(msg) do
    GenServer.cast(__MODULE__, {:handle_nerves_hub_fwup_message, msg})
    :ok
  end

  @impl NervesHub.Client
  def update_available(data) do
    GenServer.call(__MODULE__, {:handle_nerves_hub_update_available, data})
    :ok
  end

  @doc """
  Checks if an update is available, and applies it.
  """
  def check_update do
    GenServer.call(__MODULE__, :check_update)
  end

  @impl GenServer
  def init(_args) do
    write_serial(serial_number())
    Process.flag(:sensitive, true)
    cert = load_cert()
    key = load_key()

    if cert && key do
      send(self(), :connect_nerves_hub)
    else
      send(self(), :connect_amqp)
    end

    {:ok, %State{conn: nil, chan: nil, jwt: nil, cert: cert, key: key, is_applying_update: false}}
  end

  @impl GenServer
  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from NervesHub AMQP channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  @impl GenServer
  def handle_info(:connect_amqp, %{conn: nil, chan: nil} = state) do
    FarmbotCore.Logger.debug(1, "Attempting to get OTA certs from AMQP.")

    with {token, %{} = jwt} when is_binary(token) <- get_jwt(),
         email when is_binary(email) <- get_email(),
         {:ok, %{} = conn} <- open_connection(email, token, jwt),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <-
           Queue.declare(chan, "#{jwt.bot}_nerves_hub", auto_delete: false, durable: true),
         :ok <-
           Queue.bind(chan, "#{jwt.bot}_nerves_hub", @exchange,
             routing_key: "bot.#{jwt.bot}.nerves_hub"
           ),
         {:ok, _tag} <- Basic.consume(chan, "#{jwt.bot}_nerves_hub", self(), []) do
      send(self(), :after_connect_amqp)
      {:noreply, %{state | conn: conn, chan: chan, jwt: jwt}}
    else
      # happens when no token is configured.
      {nil, nil} ->
        FarmbotCore.Logger.debug(3, "No credentials yet. Can't connect to OTA Server.")
        Process.send_after(self(), :connect_amqp, 15_000)
        {:noreply, %{state | conn: nil, chan: nil, jwt: nil}}

      err ->
        FarmbotCore.Logger.error(
          3,
          "Failed to connect to NervesHub AMQP channel: #{inspect(err)}"
        )

        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil, jwt: nil}}
    end
  end

  def handle_info(:after_connect_amqp, %{key: nil, cert: nil} = state) do
    FarmbotCore.Logger.debug(3, "Connected to NervesHub AMQP channel. Fetching certs.")
    old_device_cert = Asset.get_device_cert(serial_number: serial_number())

    tags = detect_tags(old_device_cert)

    params = %{
      serial_number: serial_number(),
      tags: tags
    }

    new_device_cert =
      case old_device_cert do
        nil -> Asset.new_device_cert(params)
        %{} -> Asset.update_device_cert(old_device_cert, params)
      end

    case new_device_cert do
      {:ok, data} ->
        FarmbotCore.Logger.debug(3, "DeviceCert created: #{inspect(data)}")
        FarmbotCore.Logger.debug(3, "Waiting for cert and key data from AMQP from farmbot api...")
        {:noreply, state}

      {:error, reason} ->
        FarmbotCore.Logger.error(1, "Failed to create device cert: #{inspect(reason)}")
        Process.send_after(self(), :after_connect_amqp, 5000)
        {:noreply, state}
    end
  end

  def handle_info(:after_connect_amqp, %{key: _key, cert: _cert} = state) do
    FarmbotCore.Logger.debug(3, "Connected to NervesHub AMQP channel. Certs already loaded")
    send(self(), :connect_nerves_hub)
    {:noreply, state}
  end

  def handle_info(:connect_nerves_hub, %{key: nil, cert: nil} = state) do
    FarmbotCore.Logger.debug(3, "Can't connect to OTA Service. Certs not loaded")
    send(self(), :connect_amqp)
    {:noreply, state}
  end

  def handle_info(:connect_nerves_hub, %{key: _key, cert: _cert} = state) do
    FarmbotCore.Logger.debug(3, "Starting OTA Service")
    # NervesHub replaces it's own env on startup. Reset it.

    supervisor = FarmbotOS
    # Stop Nerves Hub if it is running.
    _ = Supervisor.terminate_child(supervisor, NervesHub.Supervisor)
    _ = Supervisor.delete_child(supervisor, NervesHub.Supervisor)

    # Cause NervesRuntime.KV to restart.
    _ = GenServer.stop(Nerves.Runtime.KV)

    # Wait for a few seconds for good luck.
    Process.sleep(1000)

    # Start the connection again.
    {:ok, _pid} = Supervisor.start_child(supervisor, NervesHub.Supervisor)
    FarmbotCore.Logger.debug(3, "OTA Service started")
    :ok
    {:noreply, state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is
  # unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    device = state.jwt.bot
    ["bot", ^device, "nerves_hub"] = String.split(key, ".")

    with {:ok, %{"cert" => base64_cert, "key" => base64_key}} <- JSON.decode(payload),
         {:ok, cert} <- Base.decode64(base64_cert),
         {:ok, key} <- Base.decode64(base64_key),
         :ok <- write_cert(cert),
         :ok <- write_key(key) do
      send(self(), :connect_nerves_hub)
      {:noreply, %{state | cert: cert, key: key}}
    else
      {:error, reason} ->
        FarmbotCore.Logger.error(1, "OTA Service failed to configure. #{inspect(reason)}")
        {:stop, reason, state}

      :error ->
        FarmbotCore.Logger.error(1, "OTA Service payload invalid. (base64)")
        {:stop, :invalid_payload, state}
    end
  end

  @impl GenServer
  def handle_cast({:handle_nerves_hub_error, error}, %{is_applying_update: true} = state) do
    FarmbotCore.Logger.error(1, "Error applying OTA: #{inspect(error)}")
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_error, error}, state) do
    FarmbotCore.Logger.debug(3, "Unexpected NervesHub error: #{inspect(error)}")
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, {:progress, percent}}, state) do
    _ = set_ota_progress(percent)
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, {:ok, _, _info}}, state) do
    _ = set_ota_progress(100)
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, {:error, _, reason}}, state) do
    _ = set_ota_progress(100)
    FarmbotCore.Logger.error(1, "Error applying OTA: #{inspect(reason)}")
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, _}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:handle_nerves_hub_update_available, %{"firmware_url" => url}}, _from, state) do
    case Asset.fbos_config(:os_auto_update) do
      true ->
        FarmbotCore.Logger.success(1, "Applying OTA update")
        {:reply, :apply, %{state | is_applying_update: true, firmware_url: url}}

      _ ->
        FarmbotCore.Logger.info(1, "New Farmbot OS is available!")
        {:reply, :ignore, %{state | firmware_url: url}}
    end
  end

  def handle_call({:handle_nerves_hub_update_available, _data}, _from, state) do
    FarmbotCore.Logger.success(1, "Applying OTA update")
    {:reply, :apply, %{state | is_applying_update: true}}
  end

  def handle_call(:check_update, _from, state) do
    case NervesHub.HTTPClient.update() do
      {:ok, %{"data" => %{"update_available" => false}}} ->
        {:reply, nil, state}

      data ->
        FarmbotCore.Logger.info(1, "Applying OTA update")
        spawn_link(fn -> NervesHub.update() end)
        {:reply, data, %{state | is_applying_update: true}}
    end
  end

  defp get_jwt do
    token = Config.get_config_value(:string, "authorization", "token")

    if token do
      {:ok, jwt} = JWT.decode(token)
      {token, jwt}
    else
      {nil, nil}
    end
  end

  defp get_email do
    Config.get_config_value(:string, "authorization", "email")
  end

  defp open_connection(email, token, jwt) do
    case ConnectionWorker.open_connection(token, email, jwt.bot, jwt.mqtt, jwt.vhost) do
      {:ok, conn} ->
        Process.link(conn.pid)
        Process.monitor(conn.pid)
        {:ok, conn}

      err ->
        FarmbotCore.Logger.error(1, "Error connecting to AMPQ: #{inspect(err)}")
        err
    end
  end

  defp filter_parens(""), do: nil
  defp filter_parens(data), do: data

  defp set_ota_progress(100) do
    FarmbotCore.Logger.success(1, "OTA Complete Going down for reboot")
    prog = %Percent{percent: 100, status: "complete"}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  defp set_ota_progress(percent) do
    prog = %Percent{percent: percent}

    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  defp detect_tags(_old_device_cert_data) do
    update_channel = Asset.fbos_config(:update_channel) || update_channel()
    ["application:#{Project.env()}", "channel:#{update_channel}"]
  end

  defp update_channel do
    case Project.branch() do
      "next" -> "next"
      "staging" -> "staging"
      "master" -> "stable"
      branch -> branch
    end
  end
end
