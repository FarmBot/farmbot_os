defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotCore.JSON

  @release_server "http://localhost:3000/api/releases?target="
  @skip %{"image_url" => nil}

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
      apply(Nerves.Runtime.KV, :get_active, "nerves_fw_platform")
    rescue
      error ->
        e = inspect(error)
        FarmbotCore.Logger.error(3, "Error getting target meta data: #{e}")
        "none"
    end
  end

  def download_meta_data(target) do
    url = to_charlist(@release_server <> target)
    http_resp = :httpc.request(:get, {to_charlist(url), []}, [], [])
    handle_http_response(http_resp)
  end

  def install_update(nil) do
    FarmbotCore.Logger.debug(3, "Not downloading update.")
  end

  def install_update(url) do
    path = "/tmp/fw#{trunc(:random.uniform() * 10000)}.fw"

    {:ok, :saved_to_file} =
      :httpc.request(:get, {to_charlist(url), []}, [], stream: to_charlist(path))

    args = ["-a", "-i", path, "-d", "/dev/mmcblk0", "-t", "upgrade"]

    {_, 0} = System.cmd("fwup", args)
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
