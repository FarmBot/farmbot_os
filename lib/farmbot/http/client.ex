defmodule Farmbot.HTTP.Client do
  use GenServer
  use Farmbot.DebugLog, name: Farmbot.HTTPClient
  alias Farmbot.HTTP.{Response, DownloadClient}

  @type headers     :: [{binary, binary}]
  @type url         :: binary
  @type http_method :: atom
  @type body        :: binary

  @type request :: {http_method, url, body, headers}
  @type client  :: pid

  @type from :: {pid, reference}

  @spec start_link(from, request) :: GenServer.on_start

  @redirect_status_codes [301, 302, 303, 307, 308]

  @doc """
    Starts an HTTP Client instance.
    * `from`    - a GenServer `from`
    * `request` - a tuple in the shape of: `{http_method, url, body, headers}`
      * where headers are in the shape of: [{char_list, char_list}]
    * `opts`    - a Keyword list described below.

    `opts` can be any of:
    * `{:save_to, file_name}` - Save to a file.
    * `{:stream_to, pid}`     - Stream to a pid.

    # Streaming
    pids that implement this stream functionality should handle the following messages.
    * `{:error, Response.t}`     - The HTTP response was not a 200 or 206
    * `{:error, term}`           - Some other HTTP error.
    * `{:stream_start, headers}` - Stream is beginning.
    * `{:stream, binary}`        - Stream data.
    * `:stream_end`              - Stream finished.
  """
  def start_link(from, request, opts) do
    GenServer.start_link(__MODULE__, {from, request, opts})
  end

  @doc """
    Manually stop a client.
  """
  def stop(client, reason \\ :normal), do: GenServer.stop(client, reason)

  def init({from, request, fb_opts}) do
    start_httpc()
    {method, url, body, headers} = ensure_request(request)
    self        = self()
    debug_log "[#{inspect self}] Starting request: #{inspect request}"
    http_opts   = [timeout: :infinity, autoredirect: false]
    opts        = [stream: self, receiver: self, sync: false]
    # headers     = [{'Content-Type', 'application/octet-stream'} | headers]
    url_headers = {url, headers}
    {:ok, ref} = :httpc.request(method, url_headers, http_opts, opts, :farmbot_http)
    state = %{
      opts:           opts,
      status_code:    nil,
      request:        request,
      headers:        [],
      from:           from,
      ref:            ref,
      buffer:         "",
    }
    {:ok, state}
  end

  # This handles the redirecting of http requests.
  def handle_info({:http, {_ref, { {_http_ver, status_code, _msg}, headers, body} } }, state) when status_code in @redirect_status_codes do
    # find the lcoation in the headers.
    new_url = get_location_from_headers(headers)

    # if we have a url
    if new_url do
      debug_log "[#{inspect self()}] redirecting to #{new_url}"

      # get the request out of the previous state.
      {method, _, body, headers} = ensure_request(state.request)
      # build the new request.
      new_request                = ensure_request({method, new_url, body, headers})

      # start a new client for that request.
      spawn __MODULE__, :start_link, [state.from, new_request, state.opts]

      # stop this client.
      {:stop, :normal, state}
    else
      # if we dont have a url, error.
      debug_log "[#{inspect self()}] could not redirect because no server was provided."
      {:stop, :redirect_error, state}
    end
  end

  # This happens when there is an http request that does NOT have a status code of
  # 200 or 206.
  def handle_info( {:http, {_ref, {{_ver, status_code, _msg}, headers, body} } }, state) do
    debug_log "[#{inspect self()}] got stream status: #{status_code}"
    new_state = %{state | status_code: status_code, buffer: body, headers: headers}
    GenServer.reply(state.from, {:ok, build_resp(new_state)})
    {:stop, :normal, state}
  end

  # Start streaming data.
  def handle_info({:http, {_ref, :stream_start, headers} }, state) do
    debug_log "[#{inspect self()}] got headers."
    new_state = %{state | headers: headers}
    {:noreply, new_state}
  end

  # Some stream data came in.
  def handle_info({:http, {_ref, :stream, data}}, state) do
    # debug_log "[#{inspect self()}] got stream data"
    # append it into the buffer.
    buffer = state.buffer <> data
    {:noreply, %{state | buffer: buffer}}
  end

  # Stream is finished.
  def handle_info({:http, {_ref, :stream_end, _headers}}, state) do
    debug_log "[#{inspect self()}] stream finish"
    new_state = %{state | status_code: 200}
    GenServer.reply(state.from, {:ok, build_resp(new_state)})
    {:stop, :normal, new_state}
  end

  # HTTP errors should just error out.
  def handle_info({:http, {error, headers}}, state) do
    new_state = %{state | headers: headers}
    {:stop, error, new_state}
  end

  def handle_call({:stream_results, data}, _, state) do
    new_state = %{state | stream_results: data}
    {:reply, :ok, new_state}
  end

  def terminate(:normal, state) do
    debug_log "[#{inspect self()}] HTTP Request seems to be finished."
    :ok
  end

  def terminate(reason,   state) do
    GenServer.reply(state.from, {:error, reason})
    if Process.alive? state.stream_to do
      debug_log "[#{inspect self()}] killing stream_to"
      Process.exit state.stream_to,  {:error, reason}
    end
    :ok
  end

  defp ensure_request({method, url, body, headers}) when is_binary(url), do: {method, String.to_char_list(url), body, headers}
  defp ensure_request({_method, _url, _body, _headers} = req), do: req

  defp get_location_from_headers([{header, val} | _]) when header == 'location', do: val
  defp get_location_from_headers([_ | rest]), do: get_location_from_headers(rest)
  defp get_location_from_headers([]), do: nil

  defp start_httpc do
    :inets.start(:httpc, profile: :farmbot_http)
    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]
    :httpc.set_options(opts, :farmbot_http)
  end

  defp stream_to(nil, _msg), do: :ok
  defp stream_to(pid, msg), do: send pid, msg

  defp build_resp(%{status_code: code, headers: headers, buffer: body}) do
    %Response{body: body, status_code: code, headers: headers}
  end
end
