defmodule Farmbot.HTTP do
  @moduledoc """
    Farmbot HTTP adapter for accessing the world and farmbot web api easily.
  """
  use     GenServer
  alias   Farmbot.{Auth, Context, Token}
  alias   HTTPoison
  alias   HTTPoison.{
    AsyncResponse,
    AsyncStatus,
    AsyncHeaders,
    AsyncChunk,
    AsyncEnd,
  }
  alias   Farmbot.HTTP.Response
  import  Farmbot.HTTP.Helpers
  require Logger
  use     Farmbot.DebugLog

  @version Mix.Project.config[:version]
  @target  Mix.Project.config[:target]
  @redirect_status_codes [301, 302, 303, 307, 308]

  def request(context, method, url, body \\ "", headers \\ [], opts \\ [])

  def request(%Context{http: http}, method, url, body, headers, opts) do
    GenServer.call(http, {:req, method, url, body, headers, opts}, :infinity)
  end

  def request!(context, method, url, body \\ "", headers \\ [], opts \\ [])

  def request!(ctx, method, url, body, headers, opts) do
    case request(ctx, method, url, body, headers, opts) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  methods = [:get, :post]

  for verb <- methods do
    @doc """
      HTTP #{verb} request.
    """
    def unquote(verb)(context, url, body \\ "", headers \\ [], opts \\ [])
    def unquote(verb)(%Context{} = ctx, url, body, headers, opts) do
       request(ctx, unquote(verb), url, body, headers, opts)
    end

    @doc """
      Same as #{verb}/5 but raises if there is an error.
    """
    fun_name = "#{verb}!" |> String.to_atom
    def unquote(fun_name)(context, url, body \\ "", headers \\ [], opts \\ [])
    def unquote(fun_name)(%Context{} = ctx, url, body, headers, opts) do
      request!(ctx, unquote(verb), url, body, headers, opts)
    end
  end

  def download_file(ctx, url, path) do
    case get(ctx, url, "", [], file: path) do
      {:ok, %Response{}} -> {:ok, path}
      {:error, reason}   -> {:error, reason}
    end
  end

  def download_file!(ctx, url, path) do
    case download_file(ctx, url, path) do
      {:ok, path}      -> path
      {:error, reason} -> raise reason
    end
  end

  def upload_file(ctx, path, meta \\ %{}) do
    if File.exists?(path) do
      ctx |> get("/api/storage_auth") |> do_multipart_request(ctx, path)
    else
      {:error, "#{path} not found"}
    end
  end

  defp do_multipart_request({:ok, %Response{status_code: code, body: bin_body}}, ctx, path) when is_2xx(code) do
    with {:ok, body} <- Poison.decode(bin_body),
         {:ok, file} <- File.read(path) do
           url            = "https:" <> body["url"]
           form_data      = body["form_data"]
           attachment_url = url <> form_data["key"]
           mp = Enum.map(form_data, fn({key, val}) -> if key == "file", do: {"file", file}, else: {key, val} end)
           HTTPoison.post!(url, {:multipart, mp})
           #TODO(Connor) fix when gcs is back up and running
         end
  end

  defp do_multipart_request({:error, reason}), do: {:error, reason}

  def upload_file!(ctx, path, meta \\ %{}) do
    case upload_file(ctx, path, meta) do
      {:ok, _} -> :ok
      {:error, reason} -> raise reason
    end
  end

  # GenServer

  defmodule State do
    defstruct [:token, :requests]
    defimpl Inspect, for: __MODULE__ do
      def inspect(state, _), do: "#HTTPState<token: #{state.token}>"
    end
  end

  defmodule Buffer do
    defstruct [:data, :headers, :status_code, :request, :from, :id, :file, :timeout]
  end

  def start_link(%Context{} = ctx, opts) do
    GenServer.start_link(__MODULE__, ctx, opts)
  end

  def init(_ctx) do
    Registry.register(Farmbot.Registry, Farmbot.Auth, [])
    state = %State{token: nil, requests: %{}}
    {:ok, state}
  end

  def handle_call({:req, method, url, body, headers, opts}, from, state) do
    {file, opts} = maybe_open_file(opts)
    opts         = fb_opts(opts)
    headers      = fb_headers(headers)

    # Pattern match the url.
    case url do
      "/api" <> _ -> do_api_request({method, url, body, headers, opts, from}, state)
      _           -> do_normal_request({method, url, body, headers, opts, from}, file, state)
    end
  end

  def handle_info({:timeout, ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        GenServer.reply buffer.from, {:error, :timeout}
        {:noreply, %{state | requests: Map.delete(state.requests, ref)}}
      nil                -> {:noreply, state}
    end
  end

  def handle_info(%AsyncStatus{code: code, id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        HTTPoison.stream_next(%AsyncResponse{id: ref})
        {:noreply, %{state | requests: %{state.requests | ref => %{buffer | status_code: code}}}}
      nil                -> {:noreply, state}
    end
  end

  def handle_info(%AsyncHeaders{headers: headers, id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        HTTPoison.stream_next(%AsyncResponse{id: ref})
        {:noreply, %{state | requests: %{state.requests | ref => %{buffer | headers: headers}}}}
      nil -> {:noreply, state}
    end
  end

  def handle_info(%AsyncChunk{chunk: chunk, id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer ->
        maybe_log_progress(buffer)
        maybe_stream_to_file(buffer.file, buffer.status_code, chunk)
        HTTPoison.stream_next(%AsyncResponse{id: ref})
        {:noreply, %{state | requests: %{state.requests | ref => %{buffer | data: buffer.data <> chunk}}}}
      nil                -> {:noreply, state}
    end
  end

  def handle_info(%AsyncEnd{id: ref}, state) do
    case state.requests[ref] do
      %Buffer{} = buffer -> finish_request(buffer, state)
      nil                -> {:noreply, state}
    end
  end

  def handle_info({Auth, {:new_token, %Token{} = token}}, state),
    do: {:noreply, %{state | token: token}}

  def handle_info({Auth, :purge_token}, state),
    do: {:noreply, %{state | token: nil}}

  def handle_info({Auth, {:error, _error}}, state), do: {:noreply, state}

  def terminate({:error, reason}, state), do: terminate(reason, state)

  def terminate(reason, state) do
    for {_ref, buffer} <- state.requests do
      maybe_close_file(buffer.file)
      GenServer.reply buffer.from, {:error, reason}
    end
  end

  defp maybe_open_file(opts) do
    {file, opts} = Keyword.pop(opts, :file)
    case file do
      filename when is_binary(filename) ->
        debug_log "Opening file: #{filename}"
        File.rm(file)
        :ok       = File.touch(filename)
        {:ok, fd} = :file.open(filename, [:write, :raw])
        {fd, opts}
      _ -> {nil, opts}
    end
  end

  defp maybe_stream_to_file(nil, _,     _data), do: :ok
  defp maybe_stream_to_file(_,   code,  _data) when code in @redirect_status_codes, do: :ok
  defp maybe_stream_to_file(fd,  _code,  data) when is_binary(data) do
    # debug_log "[#{inspect self()}] writing data to file."
    :ok = :file.write(fd, data)
  end

  defp maybe_close_file(nil), do: :ok
  defp maybe_close_file(fd), do: :file.close(fd)

  defp maybe_log_progress(%Buffer{file: file}) when is_nil(file), do: :ok

  defp maybe_log_progress(%Buffer{file: _file} = buffer) do
    data_mbs = buffer.data |> byte_size() |> bytes_to_mb()
    case Enum.find_value(buffer.headers, fn({header, val}) -> if header == "Content-Length", do: val, else: nil end) do
      numstr when is_binary(numstr) ->
        total = numstr |> String.to_integer() |> bytes_to_mb()
        do_log to_percent(data_mbs, total)
      _ -> do_log(data_mbs, false)
    end
  end

  defp do_log(num, percent \\ true)

  defp do_log(num, percent) when (rem(round(num), 5)) == 0 do
    id = if percent, do: "%", else: "MB"
    Logger.info "Download progress: #{round(num)}#{id}", type: :busy
  end

  defp do_log(_,_), do: :ok

  defp bytes_to_mb(bytes),      do: (bytes / 1024)  / 1024
  defp to_percent(part, whole), do: (part / whole) *  100

  defp do_api_request({_method, _url, _body, _headers, _opts, _from}, %{token: nil} = state) do
    {:reply, {:error, :no_token}, state}
  end

  defp do_api_request({method, url, body, headers, opts, from}, %{token: tkn} = state) do
    headers = headers
              |> add_header({"Authorization", "Bearer " <> tkn.encoded})
              |> add_header({"Content-Type", "application/json"})
    url = tkn.unencoded.iss <> url
    do_normal_request({method, url, body, headers, opts, from}, nil, state)
  end

  defp do_normal_request({method, url, body, headers, opts, from}, file, state) do
    case HTTPoison.request(method, url, body, headers, opts) do
      {:ok, %AsyncResponse{id: ref}} ->
        timeout = Process.send_after(self(), {:timeout, ref}, 30_000)
        req = %Buffer{
          id:          ref,
          from:        from,
          timeout:     timeout,
          file:        file,
          data:        "",
          headers:     nil,
          status_code: nil,
          request:     {method, url, body, headers, opts},
        }
        {:noreply, %{state | requests: Map.put(state.requests, ref, req)}}
      {:error, %HTTPoison.Error{reason: reason}} -> {:reply, {:error, reason}, state}
      {:error, reason}                           -> {:reply, {:error, reason}, state}
    end
  end

  defp do_redirect_request(%Buffer{} = buffer, redir, state) do
    {method, _url, body, headers, opts} = buffer.request
    case HTTPoison.request(method, redir, body, headers, opts) do
      {:ok, %AsyncResponse{id: ref}} ->
        req = %Buffer{
          id:          ref,
          from:        buffer.from,
          file:        buffer.file,
          data:        "",
          headers:     nil,
          status_code: nil,
          request:     {method, redir, body, headers, opts},
        }
        state = %{state | requests: Map.delete(state.requests, buffer.id)}
        state = %{state | requests: Map.put(state.requests, ref, req)}
        {:noreply, state}
      {:error, %HTTPoison.Error{reason: reason}} -> {:reply, {:error, reason}, state}
      {:error, reason}                           -> {:reply, {:error, reason}, state}
    end
  end

  defp finish_request(%Buffer{status_code: status_code} = buffer, state) when status_code in @redirect_status_codes do
    redir = Enum.find_value(buffer.headers, fn({header, val}) -> if header == "Location", do: val, else: false end)
    if redir do
      do_redirect_request(buffer, redir, state)
    else
      GenServer.reply(buffer.from, {:error, :no_server_for_redirect})
      {:noreply, state}
    end
  end

  defp finish_request(buffer, state) do
    response = %Response{
      status_code: buffer.status_code,
      body:        buffer.data,
      headers:     buffer.headers
    }
    maybe_close_file(buffer.file)
    GenServer.reply(buffer.from, {:ok, response})
    {:noreply, %{state | requests: Map.delete(state.requests, buffer.id)}}
  end

  defp fb_headers(headers) do
    headers |> add_header({"User-Agent", "FarmbotOS/#{@version} (#{@target}) #{@target} ()"})
  end

  defp add_header(headers, new), do: [new | headers]

  defp fb_opts(opts) do
    Keyword.merge(opts, [
      # ssl: [{:versions, [:'tlsv1.2']}],
      hackney:         [:insecure],
      recv_timeout:    :infinity,
      timeout:         :infinity,
      stream_to:       self(),
      follow_redirect: false,
      async:           :once
      ])
  end

end
