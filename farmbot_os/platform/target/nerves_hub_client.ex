defmodule Farmbot.System.NervesHubClient do
  @moduledoc """
  Client that decides when an update should be done.
  """

  use GenServer
  require Farmbot.Logger
  alias Farmbot.BotState.JobProgress

  @behaviour NervesHub.Client
  @behaviour Farmbot.System.NervesHub

  @current_version Farmbot.Project.version()
  @data_path Farmbot.OS.FileSystem.data_path()
  @data_path || Mix.raise("Please configure data_path in application env")

  import Farmbot.Config, only: [get_config_value: 3]

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

  def uuid, do: Nerves.Runtime.KV.get_active("nerves_fw_uuid")

  def serial_number, do: serial_number(Farmbot.Project.target())

  def connect do
    Farmbot.Logger.debug(3, "Starting OTA Service")
    # NervesHub replaces it's own env on startup. Reset it.
    Application.put_env(:nerves_hub, NervesHub.Socket, reconnect_interval: 5000)

    supervisor = Farmbot.System.Supervisor
    # Stop Nerves Hub if it is running.
    _ = Supervisor.terminate_child(supervisor, NervesHub.Supervisor)
    _ = Supervisor.delete_child(supervisor, NervesHub.Supervisor)

    # Cause NervesRuntime.KV to restart.
    _ = GenServer.stop(Nerves.Runtime.KV)

    # Wait for a few seconds for good luck.
    Process.sleep(1000)

    # Start the connection again.
    {:ok, _pid} = Supervisor.start_child(supervisor, NervesHub.Supervisor)
    Logger.debug(3, "OTA Service started")
    :ok
  end

  def provision(serial) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_serial_number", serial)
    Nerves.Runtime.KV.UBootEnv.put("nerves_fw_serial_number", serial)
  end

  def configure_certs(cert, key) do
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_cert", cert)
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_key", key)
    :ok
  end

  def deconfigure() do
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_cert", "")
    Nerves.Runtime.KV.UBootEnv.put("nerves_hub_key", "")
    Nerves.Runtime.KV.UBootEnv.put("nerves_serial_number", "")
    Nerves.Runtime.KV.UBootEnv.put("nerves_fw_serial_number", "")
    :ok
  end

  def config() do
    [
      Nerves.Runtime.KV.get("nerves_fw_serial_number"),
      Nerves.Runtime.KV.get("nerves_hub_cert"),
      Nerves.Runtime.KV.get("nerves_hub_key")
    ]
    |> Enum.map(fn val ->
      if val == "", do: nil, else: val
    end)
  end

  def check_update do
    case GenServer.call(__MODULE__, :check_update) do
      # If updates were disabled, and an update is queued
      {:ignore, _url} ->
        Farmbot.Logger.info(1, "Applying OTA update")
        NervesHub.update()

      _ ->
        Farmbot.Logger.debug(1, "No update cached. Checking for tag changes.")

        case NervesHub.HTTPClient.update() do
          {:ok, %{"data" => %{"update_available" => false}}} ->
            do_backup_strats()

          _ ->
            Farmbot.Logger.info(1, "Applying OTA update")
            NervesHub.update()
        end
    end
  end

  defp do_backup_strats do
    case Farmbot.System.Updates.check_updates() do
      {version, url} ->
        Logger.busy(1, "Downloading fallback OTA")
        Farmbot.System.Updates.download_and_apply_update({version, url})
        :ok

      _ ->
        Logger.success(1, "Farmbot is up to date!")
        nil
    end
  end

  # Callback for NervesHub.Client
  def update_available(args) do
    GenServer.call(__MODULE__, {:update_available, args}, :infinity)
  end

  def handle_error(args) do
    Farmbot.Logger.error(1, "OTA failed to download: #{inspect(args)}")
    prog = %JobProgress.Percent{status: :error}

    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:ok, _, _info}) do
    Farmbot.Logger.success(1, "OTA Complete Going down for reboot")
    prog = %JobProgress.Percent{percent: 100, status: :complete}

    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:progress, 100}) do
    Farmbot.Logger.success(1, "OTA Complete. Going down for reboot")
    prog = %JobProgress.Percent{percent: 100, status: :complete}

    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:progress, percent}) when rem(percent, 5) == 0 do
    prog = %JobProgress.Percent{percent: percent}

    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message({:error, _, reason}) do
    Farmbot.Logger.error(1, "OTA failed to apply: #{inspect(reason)}")
    prog = %JobProgress.Percent{status: :error}

    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end

    :ok
  end

  def handle_fwup_message(_) do
    :ok
  end

  def start_link(_, _) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    maybe_post_update()
    {:ok, nil}
  end

  def handle_call({:update_available, %{"firmware_url" => url}}, _, _state) do
    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_update_available(true)
    end

    case Farmbot.Asset.fbos_config(:os_auto_update) do
      true ->
        Farmbot.Logger.success(1, "Applying OTA update")
        {:reply, :apply, {:apply, url}}

      false ->
        Farmbot.Logger.info(1, "New Farmbot OS is available!")
        {:reply, :ignore, {:ignore, url}}
    end
  end

  def handle_call(:check_update, _from, state) do
    {:reply, state, state}
  end

  defp maybe_post_update do
    case File.read(update_file()) do
      {:ok, @current_version} ->
        :ok

      {:ok, old_version} ->
        Logger.info(1, "Updating FarmbotOS from #{old_version} to #{@current_version}")
        do_post_update()

      {:error, :enoent} ->
        Logger.info(1, "Setting up FarmbotOS #{@current_version}")

      {:error, err} ->
        raise err
    end

    before_update()
  end

  defp do_post_update do
    alias Farmbot.Firmware.UartHandler.Update
    hw = get_config_value(:string, "settings", "firmware_hardware")
    is_beta? = Farmbot.Project.branch() in ["beta", "staging"]

    if is_beta? do
      Logger.debug(1, "Forcing beta image arduino firmware flash.")
      Update.force_update_firmware(hw)
    else
      Update.maybe_update_firmware(hw)
    end
  end

  defp before_update, do: File.write!(update_file(), @current_version)

  defp update_file, do: Path.join(@data_path, "update")
end
