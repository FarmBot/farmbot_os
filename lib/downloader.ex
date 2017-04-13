defmodule Downloader do
  @moduledoc """
    Blatently ripped off
    from: https://github.com/nerves-project/nerves/blob/master/lib/nerves/utils/http_client.ex
  """
  use GenServer

  @progress_steps 50
  @redirect_status_codes [301, 302, 303, 307, 308]

  def start_link do
    start_httpc()
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop(client \\ __MODULE__) do
    GenServer.stop(client)
  end

  def get(client \\ __MODULE__, url) do
    GenServer.call(client, {:get, url}, :infinity)
  end

  def run(url, path) do
    {:ok, file} = get(__MODULE__, url)
    :ok = File.write!(path, file)
    if File.exists?(path) do
      path
    else
      throw :NO_FILE
    end
  end

  def init([]) do
    {:ok, %{
      url: nil,
      content_length: 0,
      buffer: "",
      buffer_size: 0,
      filename: "",
      caller: nil,
      number_of_redirects: 0,
    }}
  end

  def handle_call({:get, _url}, _, %{number_of_redirects: n}=s) when n > 5 do
    GenServer.reply(s.caller, {:error, :too_many_redirects})
    {:noreply, %{s | url: nil, number_of_redirects: 0, caller: nil}}
  end

  def handle_call({:get, url}, from, s) do
    headers = [
      {'Content-Type', 'application/octet-stream'}
    ]

    http_opts = [timeout: :infinity, autoredirect: false]
    opts = [stream: :self, receiver: self(), sync: false]
    :httpc.request(:get,
      {String.to_char_list(url), headers}, http_opts, opts, :nerves)
    {:noreply, %{s | url: url, caller: from}}
  end

  @lint false
  def handle_info({:http, {_, :stream_start, headers}}, s) do
    {_, content_length} =
      headers
      |> Enum.find(fn({key, _}) -> key == 'content-length' end)

    {content_length, _} =
      content_length
      |> to_string()
      |> Integer.parse()

    {_, filename} =
      headers
      |> Enum.find(fn({key, _}) -> key == 'content-disposition' end)
    filename =
      filename
      |> to_string
      |> String.split(";")
      |> List.last
      |> String.strip
      |> String.trim("filename=")
    {:noreply, %{s | content_length: content_length, filename: filename}}
  end

  def handle_info({:http, {_, :stream, data}}, s) do
    size = byte_size(data) + s.buffer_size
    buffer = s.buffer <> data
    put_progress(size, s.content_length)
    {:noreply, %{s | buffer_size: size, buffer: buffer}}
  end

  def handle_info({:http, {_, :stream_end, _headers}}, s) do
    IO.write(:stderr, "\n")
    GenServer.reply(s.caller, {:ok, s.buffer})
    {:noreply, %{s | filename: "", content_length: 0, buffer: "", buffer_size: 0, url: nil}}
  end

  def handle_info({:http, {_ref, {{_, status_code, _}, headers, _body}}}, s) when status_code in @redirect_status_codes do
    case Enum.find(headers, fn({key,_}) -> key == 'location' end) do
      {'location', next_url} ->
        handle_call({:get, List.to_string(next_url)}, s.caller, %{s | buffer: "", buffer_size: 0, number_of_redirects: s.number_of_redirects + 1})
      _ ->
        GenServer.reply(s.caller, {:error, status_code})
    end
  end

  def handle_info({:http, {error, _headers}}, s) do
    GenServer.reply(s.caller, {:error, error})
    {:noreply, s}
  end

  def terminate(reason, state) do
    GenServer.reply(state.caller, {:error, reason})
  end

  def put_progress(size, max) do
    fraction = (size / max)
    completed = trunc(fraction * @progress_steps)
    percent = trunc(fraction * 100)
    unfilled = @progress_steps - completed
    IO.write(:stderr, "\r|#{String.duplicate("=", completed)}#{String.duplicate(" ", unfilled)}| #{percent}% (#{bytes_to_mb(size)} / #{bytes_to_mb(max)}) MB")
  end

  defp start_httpc do
    :inets.start(:httpc, profile: :nerves)
    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]
    :httpc.set_options(opts, :nerves)
  end

  defp bytes_to_mb(bytes) do
    trunc(bytes / 1024 / 1024)
  end
end
