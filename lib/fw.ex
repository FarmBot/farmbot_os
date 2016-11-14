defmodule Fw do
  require Logger
  use Supervisor
  @env Mix.env
  @target System.get_env("NERVES_TARGET") || "rpi3"
  @version Path.join(__DIR__ <> "/..", "VERSION") |> File.read! |> String.strip
  @state_path Application.get_env(:fb, :state_path)

  @doc """
    Shortcut to Nerves.Firmware.reboot
  """
  def reboot do
    Nerves.Firmware.reboot
  end


  @doc """
    Shortcut to Nerves.Firmware.poweroff
  """
  def poweroff do
    Nerves.Firmware.poweroff
  end

  @doc """
    Formats the sytem partition, and mounts as read/write
  """
  def format_state_part do
    Logger.warn("FORMATTING DATA PARTITION!")
    System.cmd("mkfs.ext4", ["/dev/mmcblk0p3", "-F"])
    System.cmd("mount", ["/dev/mmcblk0p3", "/state", "-t", "ext4"])
    File.write("/state/.formatted", "DONT CAT ME\n")
    :ok
  end

  def fs_init(:prod) do
    with {:error, :enoent} <- File.read("#{@state_path}/.formatted") do
      format_state_part
    end
  end

  def fs_init(_) do
    :ok
  end

  def init([%{target: target, compat_version: compat_version}]) do
    children = [
      worker(SafeStorage, [@env], restart: :permanent),
      worker(BotState, [%{target: target, compat_version: compat_version}], restart: :permanent),
      worker(Command.Tracker, [[]], restart: :permanent),
      worker(SSH, [@env], restart: :permanent),
      supervisor(Controller, [[]], restart: :permanent)
    ]
    opts = [strategy: :one_for_one, name: Fw]
    supervise(children, opts)
  end

  def start(_type, args) do
    fs_init(@env)
    Logger.debug("Starting Firmware on Target: #{@target}")
    Supervisor.start_link(__MODULE__, args)
  end

  def version do
    @version
  end

  def factory_reset do
    GenServer.stop SafeStorage, :reset
    Nerves.Firmware.reboot
  end

  @doc """
    Looks for the latest asset of given extension (ie: ".exe")
    on a Github Release API.
    Returns {:update, url_to_latest_download} or :no_updates
    TODO: Rewrite this using 'with'
  """
  def check_updates(url, extension) when is_bitstring(extension) do
    Logger.debug(url)
    resp = HTTPotion.get url,
    [headers: ["User-Agent": "Farmbot"]]
    current_version = Fw.version
    case resp do
      %HTTPotion.ErrorResponse{message: error} ->
        RPC.MessageHandler.log("Update check failed: #{inspect error}", [:error_toast], ["BotUpdates"])
        {:error, "Check Updates failed", error}
      %HTTPotion.Response{body: body,
                          headers: _headers,
                          status_code: 200} ->
        json = Poison.decode!(body)
        "v"<>new_version = Map.get(json, "tag_name")
        new_version_url = Map.get(json, "assets")
        |> Enum.find(fn asset ->
                     String.contains?(Map.get(asset, "browser_download_url"),
                                            extension) end)
        |> Map.get("browser_download_url")
        Logger.debug("new version: #{new_version}, current_version: #{current_version}")
        case (new_version != current_version) do
          true ->
            RPC.MessageHandler.log("New update available!", [:success_toast, :ticker], ["BotUpdates"])
            {:update, new_version_url}
          _ ->
            RPC.MessageHandler.log("Bot up to date!", [:success_toast, :ticker], ["BotUpdates"])
            :no_updates
        end

      %HTTPotion.Response{body: body,
                          headers: _headers,
                          status_code: 301} ->
        msg = Poison.decode!(body)
        Map.get(msg, "url") |> check_updates(extension)
    end
  end

  @doc """
    Shortcut for check_updates
  """
  def check_os_updates do
    with {:ok, token} <- FarmbotAuth.get_token,
    do: check_updates(
          Map.get(token, "unencoded") |> Map.get("os_update_server"),
          ".fw")
  end

  @doc """
    Shortcut for check_updates
  """
  def check_fw_updates do
    with {:ok, token} <- FarmbotAuth.get_token,
    do: check_updates(
          Map.get(token, "unencoded") |> Map.get("fw_update_server"),
          ".hex")
  end

  def check_and_download_os_update do
    case Fw.check_os_updates do
      :no_updates ->  RPC.MessageHandler.log("Bot OS up to date!", [:success_toast, :ticker], ["BotUpdates"])
       {:update, url} ->
         Logger.debug("NEW OS UPDATE")
         spawn fn -> Downloader.download_and_install_os_update(url) end
       {:error, message} ->
         RPC.MessageHandler.log("Error fetching update: #{message}", [:error_toast], ["BotUpdates"])
       error ->
         RPC.MessageHandler.log("Error fetching update: #{inspect error}", [:error_toast], ["BotUpdates"])
    end
  end

  def check_and_download_fw_update do
    case Fw.check_fw_updates do
      :no_updates -> RPC.MessageHandler.log("Bot FW up to date!", [:success_toast, :ticker], ["BotUpdates"])
       {:update, url} ->
          Logger.debug("NEW FIRMWARE UPDATE")
          spawn fn -> Downloader.download_and_install_fw_update(url) end
      {:error, message} -> RPC.MessageHandler.log("Error fetching update: #{message}", [:error_toast], ["BotUpdates"])
    end
  end
end
