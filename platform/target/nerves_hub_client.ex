defmodule Farmbot.System.NervesHubClient do
  @moduledoc """
  Client that decides when an update should be done.
  """

  use GenServer
  use Farmbot.Logger
  alias Farmbot.BotState.JobProgress

  @behaviour NervesHub.Client
  @behaviour Farmbot.System.NervesHub
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3]

  def serial_number("rpi0"), do: serial_number("rpi")
  def serial_number("rpi3"), do: serial_number("rpi")

  def serial_number(plat) do
    :os.cmd('/usr/bin/boardid -b uboot_env -u nerves_serial_number -b uboot_env -u serial_number -b #{plat}')
    |> to_string()
    |> String.trim()
  end

  def serial_number, do: serial_number(Farmbot.Project.target())

  def connect do
    Logger.debug 3, "Starting OTA Service"
    # NervesHub replaces it's own env on startup. Reset it.
    Application.put_env(:nerves_hub, NervesHub.Socket, [reconnect_interval: 5000])
    # Stop Nerves Hub if it is running.
    _ = Application.stop(:nerves_hub)
    # Cause NervesRuntime.KV to restart.
    _ = GenServer.stop(Nerves.Runtime.KV)
    {:ok, _} = Application.ensure_all_started(:nerves_hub)
    # Wait for a few seconds for good luck.
    Process.sleep(1000)
    _r = NervesHub.connect()
    Logger.debug 3, "OTA Service started"
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
      Nerves.Runtime.KV.get("nerves_hub_key"),
    ]
    |> Enum.map(fn(val) ->
      if val == "", do: nil, else: val
    end)
  end

  def check_update do
    case GenServer.call(__MODULE__, :check_update) do
      # If updates were disabled, and an update is queued
      {:ignore, _url} ->
        Logger.info 1, "Applying OTA update"
        NervesHub.update()
      _ ->
        Logger.debug 1, "No update cached. Checking for tag changes."
        case NervesHub.HTTPClient.update() do
          {:ok, %{"data" => %{"update_available" => false}}} ->
            do_backup_strats()
          _ ->
            Logger.info 1, "Applying OTA update"
            NervesHub.update()
        end
    end
  end

  defp do_backup_strats do
    case Farmbot.System.Updates.check_updates() do
      {version, url} ->
        Logger.busy 1, "Downloading fallback OTA"
        Farmbot.System.Updates.download_and_apply_update({version, url})
        :ok
      _ ->
        Logger.success 1, "Farmbot is up to date!"
        nil
    end
  end

  # Callback for NervesHub.Client
  def update_available(args) do
    GenServer.call(__MODULE__, {:update_available, args}, :infinity)
  end

  def handle_error(args) do
    Logger.error 1, "OTA failed to download: #{inspect(args)}"
    prog = %JobProgress.Percent{status: :error}
    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end
    :ok
  end

  def handle_fwup_message({:ok, _, info}) do
    Logger.success 1, "OTA Complete Going down for reboot"
    prog = %JobProgress.Percent{percent: 100, status: :complete}
    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_job_progress("FBOS_OTA", prog)
    end
    :ok
  end

  def handle_fwup_message({:progress, 100}) do
    Logger.success 1, "OTA Complete. Going down for reboot"
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
    Logger.error 1, "OTA failed to apply: #{inspect(reason)}"
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
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, nil}
  end

  def handle_call({:update_available, %{"firmware_url" => url}}, _, _state) do
    if Process.whereis(Farmbot.BotState) do
      Farmbot.BotState.set_update_available(true)
    end
    case get_config_value(:bool, "settings", "os_auto_update") do
      true ->
        Logger.success 1, "Applying OTA update"
        {:reply, :apply, {:apply, url}}
      false ->
        Logger.info 1, "New Farmbot OS is available!"
        {:reply, :ignore, {:ignore, url}}
    end
  end

  def handle_call(:check_update, _from, state) do
    {:reply, state, state}
  end
end
