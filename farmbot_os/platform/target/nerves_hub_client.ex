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
    2b) if not available, create. goto 3.
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
  alias FarmbotCore.{BotState, BotState.JobProgress.Percent, Config}
  alias FarmbotCore.{Asset, Asset.Private, Config, JSON}
  alias FarmbotExt.JWT
  require FarmbotCore.Logger
  require Logger

  alias FarmbotExt.AMQP.ConnectionWorker
  @behaviour NervesHub.Client

  @exchange "amq.topic"
  # one hour
  @checkup_timeout_ms 600_000

  defstruct [
    :conn,
    :chan,
    :jwt,
    :key,
    :cert,
    :is_applying_update,
    :firmware_url,
    :probably_connected
  ]

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
  def load_cert,
    do: Nerves.Runtime.KV.get_active("nerves_hub_cert") |> filter_parens()

  @doc "Loads the key from storage"
  def load_key,
    do: Nerves.Runtime.KV.get_active("nerves_hub_key") |> filter_parens()

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
  end

  @doc """
  Checks if an update is available, and applies it.
  """
  def check_update do
    GenServer.call(__MODULE__, :check_update)
  end

  def do_restart_nerves_hub do
    try do
      # NervesHub replaces it's own env on startup. Reset it.
      # Stop Nerves Hub if it is running.
      _ =
        Supervisor.terminate_child(
          FarmbotOS.Init.Supervisor,
          NervesHub.Supervisor
        )

      _ =
        Supervisor.delete_child(FarmbotOS.Init.Supervisor, NervesHub.Supervisor)

      cert = load_cert()
      key = load_key()

      if cert && key do
        # Cause NervesRuntime.KV to restart.
        # _ = GenServer.stop(Nerves.Runtime.KV, :restart)
        _ = Application.stop(:nerves_runtime)
        Process.sleep(1000)
        _ = Application.ensure_all_started(:nerves_runtime)
        _ = Application.ensure_all_started(:nerves_hub)

        # Wait for a few seconds for good luck.
        Process.sleep(1000)
      end
    catch
      kind, err ->
        IO.warn(
          "NervesHub error: #{inspect(kind)} #{inspect(err)}",
          __STACKTRACE__
        )

        FarmbotCore.Logger.error(
          1,
          "OTA service error: #{kind} #{inspect(err)}"
        )
    end

    # Start the connection again.
    Supervisor.start_child(FarmbotOS, NervesHub.Supervisor)
  end

  @impl GenServer
  def init(_args) do
    Application.ensure_all_started(:nerves_runtime)
    Application.ensure_all_started(:nerves_hub)
    write_serial(serial_number())
    cert = load_cert()
    key = load_key()

    _ = set_controller_uuid()

    if cert && key do
      send(self(), :connect_nerves_hub)
    else
      send(self(), :connect_amqp)
    end

    {:ok,
     %State{
       conn: nil,
       chan: nil,
       jwt: nil,
       cert: cert,
       key: key,
       is_applying_update: false,
       probably_connected: false
     }}
  end

  @impl GenServer
  def terminate(reason, state) do
    FarmbotCore.Logger.error(
      1,
      "Disconnected from NervesHub AMQP channel: #{inspect(reason)}"
    )

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
           Queue.declare(chan, "#{jwt.bot}_nerves_hub",
             auto_delete: false,
             durable: true
           ),
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
        FarmbotCore.Logger.debug(
          3,
          "No credentials yet. Can't connect to OTA Server."
        )

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
    FarmbotCore.Logger.debug(
      3,
      "Connected to NervesHub AMQP channel. Fetching certs."
    )

    old_device_cert = Asset.get_device_cert(serial_number: serial_number())

    tags = detect_deployment_tags()

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
      {:ok, _data} ->
        # DO NOT DO THIS. The api will do it behind the scenes
        # Asset.update_device!(%{update_channel: detect_update_channel()})
        FarmbotCore.Logger.debug(3, "DeviceCert created")

        FarmbotCore.Logger.debug(
          3,
          "Waiting for cert and key data from AMQP from farmbot api..."
        )

        {:noreply, state}

      {:error, reason} ->
        FarmbotCore.Logger.error(
          1,
          "Failed to create device cert: #{inspect(reason)}"
        )

        Process.send_after(self(), :after_connect_amqp, 5000)
        {:noreply, state}
    end
  end

  def handle_info(:after_connect_amqp, %{key: _key, cert: _cert} = state) do
    FarmbotCore.Logger.debug(
      3,
      "Connected to NervesHub AMQP channel. Certs already loaded"
    )

    send(self(), :connect_nerves_hub)
    {:noreply, state}
  end

  def handle_info(:connect_nerves_hub, %{key: nil, cert: nil} = state) do
    FarmbotCore.Logger.debug(
      3,
      "Can't connect to OTA Service. Certs not loaded"
    )

    send(self(), :connect_amqp)
    {:noreply, state}
  end

  def handle_info(
        :connect_nerves_hub,
        %{key: _key, cert: _cert, probably_connected: false} = state
      ) do
    FarmbotCore.Logger.debug(3, "Starting OTA Service")
    do_restart_nerves_hub()
    FarmbotCore.Logger.debug(3, "OTA Service started")
    {:noreply, %{state | probably_connected: true}}
  end

  def handle_info(
        :connect_nerves_hub,
        %{key: _key, cert: _cert, probably_connected: true} = state
      ) do
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

    with {:ok, %{"cert" => base64_cert, "key" => base64_key}} <-
           JSON.decode(payload),
         {:ok, cert} <- Base.decode64(base64_cert),
         {:ok, key} <- Base.decode64(base64_key),
         :ok <- write_cert(cert),
         :ok <- write_key(key) do
      send(self(), :connect_nerves_hub)
      {:noreply, %{state | cert: cert, key: key}}
    else
      {:error, reason} ->
        FarmbotCore.Logger.error(
          1,
          "OTA Service failed to configure. #{inspect(reason)}"
        )

        {:stop, reason, state}

      :error ->
        FarmbotCore.Logger.error(1, "OTA Service payload invalid. (base64)")
        {:stop, :invalid_payload, state}
    end
  end

  def handle_info(
        :checkup,
        %{is_applying_update: false, probably_connected: true} = state
      ) do
    if should_auto_apply_update?() && update_available?() do
      FarmbotCore.Logger.busy(1, "Applying OTA update (1)")
      run_update_but_only_once()
      {:noreply, %{state | is_applying_update: true}}
    else
      Process.send_after(self(), :checkup, @checkup_timeout_ms)
      {:noreply, state}
    end
  end

  def handle_info(:checkup, state) do
    FarmbotCore.Logger.debug(3, """
    unknown state for checkup
    currently applying update?: #{state.is_applying_update}
    currently connected?: #{state.probably_connected}
    update available?: #{is_binary(state.firmware_url)}
    """)

    Process.send_after(self(), :checkup, @checkup_timeout_ms)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:handle_nerves_hub_error, error},
        %{is_applying_update: true} = state
      ) do
    FarmbotCore.Logger.error(1, "Error applying OTA (1): #{inspect(error)}")
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_error, error}, state) do
    FarmbotCore.Logger.debug(3, "Unexpected NervesHub error: #{inspect(error)}")
    {:noreply, state}
  end

  def handle_cast(
        {:handle_nerves_hub_fwup_message, {:progress, percent}},
        state
      ) do
    _ = set_ota_progress(percent)
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, {:ok, _, _info}}, state) do
    _ = set_firmware_needs_flash()
    _ = set_ota_progress(100)
    _ = update_device()
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, {:error, _, reason}}, state) do
    _ = set_ota_progress(100)
    FarmbotCore.Logger.error(1, "Error applying OTA (2): #{inspect(reason)}")
    {:noreply, state}
  end

  def handle_cast({:handle_nerves_hub_fwup_message, _}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(
        {:handle_nerves_hub_update_available, %{"firmware_url" => url}},
        _from,
        state
      ) do
    case should_auto_apply_update?() do
      true ->
        FarmbotCore.Logger.busy(1, "Applying OTA update (2)")
        _ = set_update_available_in_bot_state()
        _ = update_device_last_ota_checkup()
        _ = set_firmware_needs_flash()
        {:reply, :apply, %{state | is_applying_update: true, firmware_url: url}}

      _ ->
        _ = set_update_available_in_bot_state()
        _ = update_device_last_ota_checkup()
        Process.send_after(self(), :checkup, @checkup_timeout_ms)
        {:reply, :ignore, %{state | firmware_url: url}}
    end
  end

  def handle_call({:handle_nerves_hub_update_available, _data}, _from, state) do
    _ = set_update_available_in_bot_state()
    _ = update_device_last_ota_checkup()
    _ = set_firmware_needs_flash()
    FarmbotCore.Logger.busy(1, "Applying OTA update (3)")
    {:reply, :apply, %{state | is_applying_update: true}}
  end

  def handle_call(:check_update, _from, state) do
    case NervesHub.HTTPClient.update() do
      {:ok, %{"data" => %{"update_available" => false}}} ->
        _ = update_device_last_ota_checkup()
        {:reply, nil, state}

      data ->
        _ = set_update_available_in_bot_state()
        _ = update_device_last_ota_checkup()
        _ = set_firmware_needs_flash()
        FarmbotCore.Logger.busy(1, "Attempting OTA update...")
        # This is where the NervesHub update gets called.
        # Maybe we can check if the BotState has job progress for "FBOS_OTA"
        run_update_but_only_once()
        {:reply, data, %{state | is_applying_update: true}}
    end
  end

  def should_auto_apply_update?(now \\ nil) do
    now = now || DateTime.utc_now()
    auto_update = Asset.fbos_config(:os_auto_update)
    ota_hour = Asset.device(:ota_hour)
    timezone = Asset.device(:timezone)
    # if ota_hour is nil, auto apply the update
    result =
      if ota_hour && timezone do
        # check that now.hour == device.ota_hour
        case Timex.Timezone.convert(now, timezone) do
          %{hour: ^ota_hour} ->
            FarmbotCore.Logger.debug(
              3,
              "current hour: #{ota_hour} (utc=#{now.hour}) == ota_hour #{
                ota_hour
              }. auto_update=#{auto_update}"
            )

            auto_update

          %{hour: now_hour} ->
            FarmbotCore.Logger.debug(
              3,
              "current hour: #{now_hour} (utc=#{now.hour}) != ota_hour: #{
                ota_hour
              }. auto_update=#{auto_update}"
            )

            false
        end
      else
        # ota_hour or timezone are nil
        FarmbotCore.Logger.debug(
          3,
          "ota_hour = #{ota_hour || "null"} timezone = #{timezone || "null"}"
        )

        !!auto_update
      end

    result && !currently_downloading?()
  end

  def update_available?() do
    _ = update_device_last_ota_checkup()

    case NervesHub.HTTPClient.update() do
      {:ok, %{"data" => %{"update_available" => false}}} ->
        false

      _data ->
        true
    end
  end

  defp update_device do
    now = DateTime.utc_now()

    _ =
      %{last_ota: now, last_ota_checkup: now}
      |> Asset.update_device!()
      |> Private.mark_dirty!(%{})
  end

  defp update_device_last_ota_checkup do
    now = DateTime.utc_now()

    _ =
      %{last_ota_checkup: now}
      |> Asset.update_device!()
      |> Private.mark_dirty!(%{})
  end

  defp set_update_available_in_bot_state() do
    if Process.whereis(BotState) do
      BotState.set_update_available(true)
    end
  end

  defp set_controller_uuid() do
    if Process.whereis(BotState) do
      BotState.set_controller_uuid(uuid())
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
    case ConnectionWorker.open_connection(
           token,
           email,
           jwt.bot,
           jwt.mqtt,
           jwt.vhost
         ) do
      {:ok, conn} ->
        Process.link(conn.pid)
        Process.monitor(conn.pid)
        {:ok, conn}

      # Squash this log since it will be displayed for the
      # main AMQP connection
      {:error, :unknown_host} = err ->
        err

      err ->
        FarmbotCore.Logger.error(
          1,
          "Error opening AMQP connection for OTA certs #{inspect(err)}"
        )

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

  def set_firmware_needs_flash() do
    # Config.update_config_value(:bool, "settings", "firmware_needs_flash", true)
    # Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    :ok
  end

  def detect_deployment_tags() do
    update_channel = detect_update_channel()
    ["application:#{Project.env()}", "channel:#{update_channel}"]
  end

  def detect_update_channel() do
    if Regex.match?(
         ~r/(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)-rc(0|[1-9]\d*)+?/,
         Project.version()
       ) do
      "beta"
    else
      case Project.branch() do
        "master" -> "stable"
        branch -> branch
      end
    end
  end

  def currently_downloading?, do: BotState.job_in_progress?("FBOS_OTA")

  def run_update_but_only_once do
    if currently_downloading?() do
      FarmbotCore.Logger.error(
        1,
        "Can't perform OTA. OTA already in progress. Restart device if problem persists."
      )
    else
      FarmbotCore.Logger.success(1, "OTA started.")
      spawn_link(fn -> NervesHub.update() end)
    end
  end
end
