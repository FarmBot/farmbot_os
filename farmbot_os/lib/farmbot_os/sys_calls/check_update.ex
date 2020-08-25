defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotCore.JSON
  alias FarmbotCore.Config

  @release_path "/api/releases?platform="
  @skip %{"image_url" => nil}
  @dl_path '/root/upgrade.fw'
  @double_flash_error "A software update is already in progress. Please wait."

  def prevent_double_installation!(path \\ to_string(@dl_path)) do
    if File.exists?(path) do
      FarmbotCore.Logger.error(3, @double_flash_error)
      raise @double_flash_error
    end
  end

  def check_update() do
    get_target()
    |> download_meta_data()
    |> Map.get("image_url", nil)
    |> install_update()

    # Probably never returns?
    :ok
  end

  def get_target() do
    # Read value set by
    try do
      apply(Nerves.Runtime.KV, :get_active, ["nerves_fw_platform"])
    rescue
      error ->
        e = inspect(error)
        FarmbotCore.Logger.error(3, "Error getting target meta data: #{e}")
        "none"
    end
  end

  def download_meta_data(target) do
    # TODO: Hard code this value to `my.farm.bot` so that self-hosters can stay
    #       up-to-date without managing releases.
    server = Config.get_config_value(:string, "authorization", "server")
    url = to_charlist(server <> @release_path <> target)
    FarmbotCore.Logger.debug(3, "Downloading meta data from #{url}")
    http_resp = :httpc.request(:get, {to_charlist(url), []}, [], [])
    handle_http_response(http_resp)
  end

  def install_update(nil) do
    FarmbotCore.Logger.debug(3, "Not downloading update.")
  end

  def install_update(url) do
    prevent_double_installation!()
    FarmbotCore.Logger.debug(3, "Downloading FBOS upgrade from #{url}")
    params = {to_charlist(url), []}

    {:ok, :saved_to_file} = :httpc.request(:get, params, [], stream: @dl_path)

    FarmbotCore.Logger.debug(
      3,
      "Finished downloading upgrade. Begin installation."
    )

    path_string = to_string(@dl_path)
    args = ["-a", "-i", path_string, "-d", "/dev/mmcblk0", "-t", "upgrade"]

    {_, 0} = System.cmd("fwup", args)

    FarmbotCore.Logger.debug(3, "Instalation complete. Cleaning up.")
    File.rm!(path_string)

    FarmbotCore.Logger.debug(3, "Going down for reboot.")

    FarmbotCeleryScript.SysCalls.reboot()
  end

  def handle_http_response({:ok, {_status_line, _response_headers, body}}) do
    {:ok, map} = JSON.decode(body)
    map
  end

  def handle_http_response(error) do
    e = "Error downloading update. Please try again. #{inspect(error)}"
    FarmbotCore.Logger.error(3, e)
    @skip
  end
end
