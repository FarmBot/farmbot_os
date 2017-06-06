defmodule Farmbot.HTTP.Client do
  use GenServer
  use Farmbot.DebugLog, name: HTTPClient
  alias Farmbot.HTTP.{Response, Types}

  @typedoc false
  @type client :: pid

  @typedoc false
  @type from   :: {pid, reference}

  @typedoc "State of the Client."
  @type state  :: %{
    noreply:     boolean,
    opts:        Keyword.t,
    status_code: nil | Types.status_code,
    request:     Types.request,
    headers:     Types.headers,
    from:        from,
    ref:         reference,
    buffer:      binary,
  }

  @redirect_status_codes [301, 302, 303, 307, 308]

  @doc """
    Execute the HTTP request.
  """
  @spec execute(client) :: :ok
  def execute(client), do: GenServer.cast(client, :execute)

  ## GenServer Stuff

  @doc """
    Starts an HTTP Client instance.
    * `from`    - a GenServer `from`
    * `request` - a tuple in the shape of: `{http_method, url, body, headers}`
      * where headers are in the shape of: [{char_list, char_list}]
    * `opts`    - a Keyword list described below.

    `opts` can be any of:
  """
  def start_link(from, request, opts) do
    GenServer.start_link(__MODULE__, {from, request, opts})
  end

  @doc "Manually stop a client."
  def stop(client, reason \\ :normal), do: GenServer.stop(client, reason)

  def init({from, request, fb_opts}) do
    {_method, _url, _body, _headers} = actual_request = ensure_request(request)
    state = %{
      stream_pid:     nil,
      file:           nil,
      noreply:        false,
      fb_opts:        fb_opts,
      status_code:    nil,
      request:        actual_request,
      headers:        [],
      from:           from,
      ref:            nil,
      buffer:         "",
    }
    {:ok, state}
  end

  def handle_cast(:execute, state) do
    start_httpc()
    file                         = maybe_open_file(state.fb_opts)
    {method, url, body, headers} = ensure_request(state.request)
    http_opts                    = [timeout: :infinity, autoredirect: false]
    opts                         = [stream: {:self, :once}, receiver: self(), sync: false]
    httpc_request                = build_httpc_request(method, url, body, headers)
    case :httpc.request(method, httpc_request, http_opts, opts, :farmbot_http) do
      {:ok, ref} ->
        state = %{ state | ref: ref, file: file}
        debug_log "[#{inspect self()}] Starting request"
        {:noreply, state}
      {:error, reason} ->
        debug_log "[#{inspect self()}] failed to create request: #{inspect reason}"
        finish_request state, reason
    end

  end

  defp build_httpc_request(:get, url, _body, headers), do: {url, headers}
  defp build_httpc_request(_method, url, body, headers) do
    content_type =
      get_from_headers('content-type', headers) || 'application/json'
    debug_log "[#{inspect self()}] using content-type: #{content_type}"
    {url, headers, content_type, body}
  end

  # This handles the redirecting of http requests.
  def handle_info({:http,
  {_ref, { {_http_ver, status_code, _msg}, headers, body} } },
  state)
  when status_code in @redirect_status_codes do
    # find the lcoation in the headers.
    new_url = get_from_headers('location', headers)

    # if we have a url
    if new_url do
      debug_log "[#{inspect self()}] redirecting to #{new_url}"

      # get the request out of the previous state.
      {method, _, body, headers} = ensure_request(state.request)
      # build the new request.
      new_request                = ensure_request({method, new_url, body, headers})

      # start a new client for that request.
      spawn fn() ->
        {:ok, pid} = start_link(state.from, new_request, state.fb_opts)
        :ok        = execute(pid)
      end

      # stop this client, but don't reply because something else is going to reply for it.
      finish_request %{state | noreply: true}
    else
      # if we dont have a url, error.
      debug_log "[#{inspect self()}] could not redirect because no server was provided."
      finish_request state, :redirect_fail
    end
  end

  # This happens when there is an http request that does NOT have a status code of
  # 200 or 206.
  def handle_info( {:http, {_ref, {{_ver, status_code, _msg}, headers, body} } }, state) do
    debug_log "[#{inspect self()}] got stream status: #{status_code}"
    new_state = %{state | status_code: status_code, buffer: body, headers: headers}
    finish_request new_state
  end

  # Start streaming data.
  def handle_info({:http, {_ref, :stream_start, headers, pid} }, state) do
    debug_log "[#{inspect self()}] got headers."
    new_state = %{state | headers: headers, stream_pid: pid}
    :httpc.stream_next(pid)
    {:noreply, new_state}
  end

  # Some stream data came in.
  def handle_info({:http, {_ref, :stream, data}}, state) do
    # debug_log "[#{inspect self()}] got stream data"
    # append it into the buffer.
    buffer = state.buffer <> data
    :ok    = maybe_stream_to_file(state.file, data)
    :httpc.stream_next(state.stream_pid)
    {:noreply, %{state | buffer: buffer}}
  end

  # Stream is finished.
  def handle_info({:http, {_ref, :stream_end, headers}}, state) do
    debug_log "[#{inspect self()}] stream finish"
    new_state = %{state | status_code: 200, headers: headers}
    finish_request new_state
  end

  # HTTP errors should just error out.
  def handle_info({:http, {error, headers}}, state) do
    new_state = %{state | headers: headers}
    finish_request new_state, error
  end

  # If we exit in a NORMAL state, we reply with :ok
  def terminate(:normal, state) do
    unless state.noreply do
      # Unless nothing told us not to, do reply.
      GenServer.reply(state.from, {:ok, build_resp(state)})
    end
    debug_log "[#{inspect self()}] HTTP Request seems to be finished."
    :ok = maybe_close_file(state.file)
    :ok
  end

  # If we exit for any other reason, it's an error.
  def terminate(reason, state) do
    # If there is an error always reply.
    GenServer.reply(state.from, {:error, reason})
    :ok = maybe_close_file(state.file)
    :ok
  end

  defp maybe_open_file(opts) do
    case Keyword.get(opts, :file) do
      file_name when is_binary(file_name) ->
        debug_log "[#{inspect self()}] opening file: #{inspect file_name}"
        :ok       = File.touch(file_name)
        {:ok, fd} = :file.open(file_name, [:write, :raw])
        fd
      nil -> nil
    end
  end

  defp maybe_close_file(nil), do: :ok
  defp maybe_close_file(fd), do: :file.close(fd)

  defp maybe_stream_to_file(nil, _data), do: :ok
  defp maybe_stream_to_file(fd, data) when is_binary(data) do
    debug_log "[#{inspect self()}] writing data to file."
    :ok = :file.write(fd, data)
  end

  @spec finish_request(state, term) :: {:stop, term, state}
  defp finish_request(state, reason \\ :normal)
  defp finish_request(state, reason), do: {:stop, reason, state}

  @spec ensure_request(any) :: Types.request | no_return
  defp ensure_request({method, url, body, headers}) when is_binary(url),
    do: {method, String.to_char_list(url), body, headers}

  defp ensure_request({_method, _url, _body, _headers} = req), do: req

  @spec get_from_headers(char_list, Types.headers) :: Types.url
  defp get_from_headers(find, headers)
  defp get_from_headers(find, [{header, val} | _]) when header == find, do: val

  defp get_from_headers(find, [_ | rest]),
    do: get_from_headers(find, rest)

  defp get_from_headers(_find, []), do: nil

  defp start_httpc do
    :inets.start(:httpc, profile: :farmbot_http)
    opts = [
      max_sessions: 9000,
      max_keep_alive_length: 9000,
      max_pipeline_length: 9000,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]
    :httpc.set_options(opts, :farmbot_http)
  end

  @spec build_resp(map) :: Types.response
  defp build_resp(%{status_code: code, headers: headers, buffer: body}) do
    %Response{body: body, status_code: code, headers: headers}
  end
end
