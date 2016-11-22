defmodule Downloader do
  @moduledoc """
    I found most of this as a very helpfulk gist.
    If i find it again I will link to it
    because it was very helpful
  """
  require Logger

  @spec run(String.t, String.t) :: String.t
  def run(url, dl_file) when is_bitstring url do
    HTTPotion.get url, stream_to: self, timeout: :infinity
    receive_data(total_bytes: :unknown, data: "", dl_path: dl_file)
  end

  defp receive_data(total_bytes: total_bytes, data: data, dl_path: path) do
    receive do
      %HTTPotion.AsyncHeaders{headers: h} ->
        {total_bytes, _} = h[:"Content-Length"] |> Integer.parse
        Logger.debug("Downloading: #{mb total_bytes}")
        receive_data(total_bytes: total_bytes, data: data, dl_path: path)

      %HTTPotion.AsyncChunk{chunk: new_data} ->
        accumulated_data = data <> new_data
        accumulated_bytes = byte_size(accumulated_data)
        percent = accumulated_bytes / total_bytes * 100 |> Float.round(2)
        Logger.debug("#{percent}% (#{mb accumulated_bytes})")
        receive_data(total_bytes: total_bytes, data: accumulated_data, dl_path: path)

      %HTTPotion.AsyncEnd{} ->
        File.write!(path, data)
        Logger.debug("Done.")
        path
    end
  end
  @spec mb(number) :: String.t
  defp mb(bytes) do
    number = bytes / 1_048_576 |> Float.round(2)
    "#{number} MB"
  end
end
