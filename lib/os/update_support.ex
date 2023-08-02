defmodule FarmbotOS.UpdateSupport do
  @moduledoc false
  require FarmbotOS.Logger
  alias FarmbotOS.JSON
  alias FarmbotOS.Config

  @skip %{"image_url" => nil}
  @dl_path ~c"/root/upgrade.fw"
  @double_flash_error "A software update is already in progress. Please wait."

  # Determines if there is an OTA update in progress.
  # Running two OTAs at the same time can have disastrous
  # side effects. We use @dl_path as a lock file to prevent
  # this. No lock file == no OTA in progress.
  def in_progress?(path \\ to_string(@dl_path)) do
    File.exists?(path)
  end

  # Delete @dl_path so that the user can run an OTA again.
  # This also conserves SD card space.
  def clean_up() do
    if in_progress?() do
      File.rm!(to_string(@dl_path))
    end
  end

  # Flash the SD card partition with the new *.fw file using
  # FWUP.
  def do_flash_firmware() do
    path_string = to_string(@dl_path)
    args = ["-a", "-i", path_string, "-d", "/dev/mmcblk0", "-t", "upgrade"]

    {_, 0} = System.cmd("fwup", args)
  end

  # Downloads an arbitrary URL to @dl_path
  def download_update_image(url) do
    params = {to_charlist(url), []}

    {:ok, :saved_to_file} =
      FarmbotOS.HTTP.request(:get, params, [], stream: @dl_path)
  end

  # Crash the current process if there is already an OTA in
  # progress.
  def prevent_double_installation!() do
    if in_progress?() do
      FarmbotOS.Logger.error(3, @double_flash_error)
      raise @double_flash_error
    end
  end

  # Bails out of an OTA early if no image URL is provided by
  # the server or if an error occurs.
  def install_update(nil) do
    {:error, "No update available."}
  end

  # Upgrades the device to an arbitrary URL pointing to a
  # *.fw file.
  def install_update(url) do
    try do
      prevent_double_installation!()
      download_update_image(url)
      do_flash_firmware()
      :ok
    rescue
      error -> error
    after
      clean_up()
    end
  end

  # FarmbotOS.HTTP callback when a JSON download succeeds (/api/releases?platform=foo)
  def handle_http_response({:ok, {{_, 200, _}, _response_headers, body}}) do
    {:ok, map} = JSON.decode(body)
    map
  end

  # :httpc callback when a JSON download succeeds (/api/releases?platform=foo)
  def handle_http_response({:ok, {{_, 422, _}, _response_headers, body}}) do
    {:ok, map} = JSON.decode(body)
    FarmbotOS.Logger.info(3, "Not updating: " <> inspect(Map.values(map)))
    @skip
  end

  # :httpc callback when a JSON download fails (/api/releases?platform=foo)
  def handle_http_response(error) do
    e = "Error downloading update. Please try again. #{inspect(error)}"
    FarmbotOS.Logger.error(3, e)
    @skip
  end

  # Fetch a release object for a particular Nerves target.
  # Note that a release is a JSON objecting that contains a
  # URL to a *.fw. It is _not_ a *.fw, however.
  def download_meta_data(target) do
    url = calculate_url(target)
    t = FarmbotOS.Config.get_config_value(:string, "authorization", "token")
    params = {to_charlist(url), [{~c"Authorization", to_charlist(t)}]}
    http_resp = FarmbotOS.HTTP.request(:get, params, [], [])
    handle_http_response(http_resp)
  end

  # Heuristic to determine the current Nerves target.
  # TODO: Is there a better way to do this?
  def get_target() do
    # Read value set by
    try do
      apply(Nerves.Runtime.KV, :get_active, ["nerves_fw_platform"])
    rescue
      error ->
        e = inspect(error)
        FarmbotOS.Logger.error(3, "Error getting target meta data: #{e}")
        "none"
    end
  end

  def calculate_url(target) do
    server = Config.get_config_value(:string, "authorization", "server")
    string = "#{server}/api/releases?platform=#{target}"
    to_charlist(string)
  end

  def get_hotfix_info() do
    device = FarmbotOS.Asset.device()
    tz = device.timezone
    ota_hour = device.ota_hour
    {tz, ota_hour}
  end

  def do_hotfix() do
    uptime = FarmbotOS.SysCalls.CheckUpdate.max_uptime()
    FarmbotOS.Logger.debug(3, "Rebooting after #{uptime} days of uptime.")
    FarmbotOS.SysCalls.reboot()
  end
end
