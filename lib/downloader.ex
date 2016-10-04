defmodule Downloader do
  @update_server Application.get_env(:fb, :update_server)
  def get_url do
    @update_server
  end
  
  def download_and_install_update(url) do
    RPCMessageHandler.log("Downloading an Update!")
    run(url, "/tmp/update.fw") |> Nerves.Firmware.upgrade_and_finalize
    RPCMessageHandler.log("Going down for update. See you soon!")
    Nerves.Firmware.reboot
  end

  def check_updates(url \\ @update_server) do
    resp = HTTPotion.get url,
    [headers: ["User-Agent": "Farmbot"]]
    current_version = Fw.version
    case resp do
      %HTTPotion.ErrorResponse{message: error} ->
        {:error, "Check Updates failed", error}
      _ ->
        json = Poison.decode!(resp.body)
        "v"<>new_version = Map.get(json, "tag_name")
        new_version_url = Map.get(json, "assets") |> List.first |> Map.get("browser_download_url")
        case (new_version != current_version) do
          true -> {:update, new_version_url}
          _ -> :no_updates
        end
    end
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
end
