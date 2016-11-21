defmodule Downloader do
  @log_tag "BotUpdates"
  require Logger
  def download_and_install_os_update(url) do
    Farmbot.Logger.log("Downloading OS update!", [:warning_toast], [@log_tag])
    File.rm("/tmp/update.fw")
    run(url, "/tmp/update.fw") |> Nerves.Firmware.upgrade_and_finalize
    Farmbot.Logger.log("Going down for OS update!", [:warning_toast], [@log_tag])
    Process.sleep(5000)
    Nerves.Firmware.reboot
  end

  def download_and_install_fw_update(url) do
    Farmbot.Logger.log("Downloading FW Update", [:warning_toast], [@log_tag])
    File.rm("/tmp/update.hex")
    file = run(url, "/tmp/update.hex")
    Farmbot.Logger.log("Installing FW Update", [], [@log_tag])
    GenServer.cast(UartHandler, {:update_fw, file})
    :ok
  end

  def run(url, dl_file) when is_bitstring url do
    HTTPotion.get url, stream_to: self, timeout: :infinity
    receive_data(total_bytes: :unknown, data: "", dl_path: dl_file)
  end

  defp receive_data(total_bytes: total_bytes, data: data, dl_path: path) do
    receive do
      %HTTPotion.AsyncHeaders{headers: h} ->

        {total_bytes, _} = h[:"Content-Length"] |> Integer.parse
        IO.puts "Let's download #{mb total_bytes}…"
        receive_data(total_bytes: total_bytes, data: data, dl_path: path)

      %HTTPotion.AsyncChunk{chunk: new_data} ->

        accumulated_data = data <> new_data
        accumulated_bytes = byte_size(accumulated_data)
        percent = accumulated_bytes / total_bytes * 100 |> Float.round(2)
        IO.puts "#{percent}% (#{mb accumulated_bytes})"
        receive_data(total_bytes: total_bytes, data: accumulated_data, dl_path: path)

      %HTTPotion.AsyncEnd{} ->

        File.write!(path, data)
        IO.puts "All downloaded! See: #{path}"
        path

    end
  end

  defp mb(bytes) do
    number = bytes / 1_048_576 |> Float.round(2)
    "#{number} MB"
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
    current_version = Farmbot.BotState.get_version
    case resp do
      %HTTPotion.ErrorResponse{message: error} ->
        Farmbot.Logger.log("Update check failed: #{inspect error}", [:error_toast], ["BotUpdates"])
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
            Farmbot.Logger.log("New update available!", [:success_toast, :ticker], ["BotUpdates"])
            {:update, new_version_url}
          _ ->
            Farmbot.Logger.log("Bot up to date!", [:success_toast, :ticker], ["BotUpdates"])
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
    with {:ok, token} <- Farmbot.Auth.get_token,
    do: check_updates(
          Map.get(token, "unencoded") |> Map.get("os_update_server"),
          ".fw")
  end

  @doc """
    Shortcut for check_updates
  """
  def check_fw_updates do
    with {:ok, token} <- Farmbot.Auth.get_token,
    do: check_updates(
          Map.get(token, "unencoded") |> Map.get("fw_update_server"),
          ".hex")
  end

  def check_and_download_os_update do
    case check_os_updates do
      :no_updates ->  Farmbot.Logger.log("Bot OS up to date!", [:success_toast, :ticker], ["BotUpdates"])
       {:update, url} ->
         Logger.debug("NEW OS UPDATE")
         spawn fn -> Downloader.download_and_install_os_update(url) end
       {:error, message} ->
         Farmbot.Logger.log("Error fetching update: #{message}", [:error_toast], ["BotUpdates"])
       error ->
         Farmbot.Logger.log("Error fetching update: #{inspect error}", [:error_toast], ["BotUpdates"])
    end
  end

  def check_and_download_fw_update do
    case check_fw_updates do
      :no_updates -> Farmbot.Logger.log("Bot FW up to date!", [:success_toast, :ticker], ["BotUpdates"])
       {:update, url} ->
          Logger.debug("NEW FIRMWARE UPDATE")
          spawn fn -> Downloader.download_and_install_fw_update(url) end
      {:error, message} -> Farmbot.Logger.log("Error fetching update: #{message}", [:error_toast], ["BotUpdates"])
    end
  end
end
