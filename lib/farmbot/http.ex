defmodule Farmbot.HTTP do
  use GenServer
  alias Farmbot.{Auth, Context, Token}
  require Logger
  use Farmbot.DebugLog

  alias HTTPoison.{Response,
    AsyncResponse,
    AsyncChunk,
    AsyncStatus,
    AsyncHeaders,
    AsyncEnd,
    Error,
  }

  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]

  defp http_config(timeout) do
    [
      ssl: [versions: [:'tlsv1.2']],
      recv_timeout: timeout,
      timeout: timeout,
      # follow_redirect: true
    ]
  end

  @doc """
    Make an HTTP Request.
    * `context` is a Farmbot.Context
    * `method` can be an atom representing an HTTP verb
    * `url` is a binary url
    * `body` is a binary http payload
    * `opts` is a keyword list of options.
  """
  def request(context, method, url, body \\ "", headers \\ [], opts \\ [])

  def request(%Context{} = ctx, method, url, body, headers, opts) do
    GenServer.call(ctx.http, {:request, method, url, body, headers, opts}, :infinity)
  end

  def request!(context, method, url, body \\ "", headers \\ [], opts \\ [])
  def request!(%Context{} = ctx, method, url, body, headers, opts) do
    debug_log "doing request!"
    case request(ctx, method, url, body, headers, opts) do
      {:ok, %Response{} = response} -> response
      {:error, er} ->
        raise "Http request #{inspect method} : #{inspect url} failed! #{inspect er}"
    end
  end

  @doc """
    HTTP GET.
  """
  def get(context, url, body \\ "", headers \\ [], opts \\ [])
  def get(%Context{} = ctx, url, body, headers, opts), do: request(ctx, :get, url, body, headers, opts)

  @doc """
    Same as `get/5` but raise if errors and returns the response body.
  """
  def get!(context, url, body \\ "", headers \\ [], opts \\ [])
  def get!(%Context{} = ctx, url, body, headers, opts) do
    case request!(ctx, :get, url, body, headers, opts) do
      %Response{status_code: 200, body: response_body} ->
        debug_log "get! complete."
        response_body
      %Response{status_code: code, body: body} ->
        raise "Invalid http response code: #{code} body: #{body}"
    end
  end


  def post(context, url, body \\ "", headers \\ [], opts \\ [])
  def post(%Context{} = ctx, url, body, headers, opts), do: request(ctx, :post, url, body, headers, opts)

  @doc """
    Downloads a file to the filesystem
  """
  def download_file!(%Context{} = ctx, url, path) do
    opts = [to_file: path]
    r    =  request(ctx, :get, url, "", [], opts)
    case r do
      {:ok, %Response{status_code: 200}} -> path
      {:error, er} ->
        if File.exists?(path) do
          File.rm! path
        end
        raise "Failed to download file: #{inspect er}"
    end
  end

  @doc """
    Uploads a file to the API
  """
  def upload_file!(%Context{} = _ctx, _url) do
    raise "Uplaoding to the API is still TODO"
  end

  ## GenServer Stuff

  @doc """
    Start a HTTP client
  """
  def start_link(%Context{} = ctx, opts) do
    GenServer.start_link(__MODULE__, ctx, opts)
  end

  def init(ctx) do
    state = %{
      context: %{ctx | http: self()},
      requests: %{}
    }
    {:ok, state}
  end

  defp empty_request, do: %{ status_code: nil, body: "", headers: [], file: nil, redirect: false}

  defp create_request({:request, method, url, body, headers, opts} = request, from, state) do
    debug_log "http request: #{method} #{url}"
    {save_to_file, opts} = Keyword.pop(opts, :to_file, false)
    {timeout,       opts} = Keyword.pop(opts, :fb_timeout, :infinity)
    new_opts   = Keyword.put(opts, :stream_to, state.context.http)
    options    = Keyword.merge(http_config(timeout), new_opts)
    user_agent = {"User-Agent", "FarmbotOS/#{@version} (#{@target}) #{@target}"}
    headers    = [user_agent | headers]
    try do
      debug_log "Trying to create request"
      %AsyncResponse{id: ref} = HTTPoison.request!(method, url, body, headers, options)
      empty_request = empty_request()
      populated = if save_to_file do
        if File.exists?(save_to_file) do
          debug_log "Deleting file with the same name"
          File.rm!(save_to_file)
        end
        File.touch!(save_to_file)
        %{empty_request | file: save_to_file}
      else
        empty_request
      end
      r_map    = {from, request, populated}
      requests = Map.put(state.requests, ref, r_map)
      debug_log "Request created: #{inspect ref}"
      %{state | requests: requests}
    rescue
      e ->
        debug_log "Error doing request: #{inspect request} #{inspect e}"
        GenServer.reply(from, {:error, e})
        state
    end
  end

  defp create_request({:api_request, method, url, body, headers, opts}, from, state) do
    maybe_token = Auth.get_token(state.context.auth)
    case maybe_token do
      {:ok, %Token{encoded: enc}} ->
        auth         = {"Authorization", "Bearer " <> enc  }
        content_type = {"Content-Type",  "application/json"}
        new_headers1 = [content_type | headers     ]
        new_headers2 = [auth         | new_headers1]
        request = {:request, method, url, body, new_headers2, opts}
        create_request(request, from, state)
      _ ->
        GenServer.reply(from, {:error, :no_token})
        state
    end
  end

  def handle_call({:request, method, "/" <> url, body, headers, opts}, from, state) do
    debug_log "redirecting #{method} request to farmbot api"
    new_state = create_request({:api_request, method, "/#{url}", body, headers, opts}, from, state)
    {:noreply, new_state}
  end

  def handle_call({:request, _method, _url, _body, _headers, _opts} = request, from, state) do
    debug_log "http request begin"
    new_state = create_request(request, from, state)
    {:noreply, new_state}
  end

  def handle_info(%Error{id: ref} = error, state) do
    request = state.requests[ref]
    case request do
      {from, _request, _map} ->
        GenServer.reply(from, {:error, error})
        new_requests = Map.delete(state.requests, ref)
        {:noreply, %{state | requests: new_requests}}
      _ ->
        debug_log "Unrecognized ref (Error): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncHeaders{id: ref, headers: headers}, state) do
    request = state.requests[ref]
    case request do
      {from, request, map} ->
        new_map  = %{map | headers: headers}
        new_requests = %{state.requests | ref => {from, request, new_map}}
        {:noreply, %{state | requests: new_requests}}
      _ ->
        debug_log "Unrecognized ref (Headers): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncStatus{id: ref, code: code}, state) do
    request = state.requests[ref]
    case request do
      {from, request, map} ->
        debug_log "Got status: #{inspect ref} code: #{code}"
        new_map = %{map | status_code: code}
        next_map =
          if code == 302 do
            %{new_map | redirect: true}
          else
            %{new_map | redirect: false}
          end
        new_requests = %{state.requests | ref => {from, request, next_map}}
        {:noreply, %{state | requests: new_requests}}
      _ ->
        debug_log "Unrecognized ref (Status): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncChunk{id: ref, chunk: chunk}, state) do
    request = state.requests[ref]
    case request do
      {from, request, map} ->
        if (is_binary(map.file)) and (map.redirect != true) do
          File.write!(map.file, chunk, [:write, :append])
        end
        new_map = %{map | body: map.body <> chunk}
        new_requests = %{state.requests | ref => {from, request, new_map}}
        {:noreply, %{state | requests: new_requests}}
      _ ->
        debug_log "Unrecognized ref (Chunk): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncEnd{id: ref}, state) do
    request = state.requests[ref]
    case request do
      {from, {:request, method, _url, body, headers, opts}, %{redirect: true} = map} ->
        # remove this request from the state
        new_requests = Map.delete(state.requests, ref)
        next_state = %{state | requests: new_requests}

        # get the next url
        next_url = Enum.find_value(map.headers, fn({header, val}) -> if header == "Location" or header == "location", do: val, else: nil end)

        if next_url do
          # create a new request
          debug_log "Doing redirect: #{inspect ref}"
          next_state = create_request({:request, method, next_url, body, headers, opts}, from, next_state)
          {:noreply, next_state}
        else
          debug_log "Could not redirect because server did not provide a new location"
          GenServer.reply(from, {:error, :redirect_error})
          {:noreply, next_state}
        end

      {from, _request, %{
        status_code: code,
        headers: headers,
        body: body
      }} ->
        debug_log "Request: #{inspect ref} has completed."
        reply = %Response{
          status_code: code,
          headers: headers,
          body: body
        }
        GenServer.reply(from, {:ok, reply})
        new_requests = Map.delete(state.requests, ref)
        {:noreply, %{state | requests: new_requests}}
      _ ->
        debug_log "Unrecognized ref (End): #{inspect ref}"
        {:noreply, state}
    end
  end
end
# defmodule Farmbot.HTTP do
#   @moduledoc """
#     Shortcuts to Http Client because im Lazy.
#   """
#   alias Farmbot.Auth
#   alias Farmbot.Token
#   require Logger
#   alias Farmbot.Context
#   use Farmbot.DebugLog
#   use GenServer
#
#   @typedoc false
#   @type http :: atom | pid
#
#   @version Mix.Project.config[:version]
#   @target Mix.Project.config[:target]
#   @twenty_five_seconds 25_000
#   @http_config [
#     ssl: [versions: [:'tlsv1.2']],
#     recv_timeout: @twenty_five_seconds,
#     timeout: @twenty_five_seconds,
#     follow_redirect: true
#   ]
#
#   @type http_resp :: HTTPoison.Response.t | {:error, HTTPoison.ErrorResponse.t}
#
#   @doc """
#     Start the Farmbot HTTP client.
#   """
#   def start_link(%Context{} = ctx, opts) do
#     GenServer.start_link(__MODULE__, ctx, opts)
#   end
#
#   def init(context) do
#     Registry.register(Farmbot.Registry, Farmbot.Auth, [])
#     {:ok, %{context: context, token: nil}}
#   end
#
#
#   defp context, do: Context.new()
#
#   def process_url(url) do
#     {:ok, server} = fetch_server(context().auth)
#     server <> url
#   end
#
#   def process_request_headers(_headers) do
#     {:ok, auth_headers} = build_auth(context())
#     auth_headers
#   end
#
#   def process_request_options(opts),
#     do: opts
#         |> Keyword.merge(@http_config, fn(_key, user_provided, _default) ->
#           user_provided
#         end)
#
#   def process_status_code(401) do
#     Logger.info ">> Token is expired!"
#     Farmbot.Auth.try_log_in!(context().auth)
#     401
#   end
#
#   def process_status_code(code), do: code
#
#   @spec build_auth(Context.t) :: {:ok, [any]} | {:error, :no_token}
#   defp build_auth(%Context{} = ctx) do
#     with {:ok, %Token{} = token} <- Auth.get_token(ctx.auth)
#     do
#       {:ok,
#         ["Content-Type": "application/json",
#          "User-Agent": "FarmbotOS/#{@version} (#{@target}) #{@target} ()",
#          "Authorization": "Bearer " <> token.encoded]}
#     else
#       _ -> {:error, :no_token}
#     end
#   end
#
#   @spec fetch_server(Context.auth) :: {:error, :no_server} | {:ok, binary}
#   defp fetch_server(auth) do
#     case Auth.get_server(auth) do
#       {:ok, nil} -> {:error, :no_server}
#       {:ok, server} -> {:ok, server}
#     end
#   end
#
#   @doc """
#     Uploads a file to google storage
#   """
#   @spec upload_file(binary) :: {:ok, HTTPoison.Response.t} | no_return
#   def upload_file(file_name) do
#     unless File.exists?(file_name) do
#       raise("File not found")
#     end
#     {:ok, %HTTPoison.Response{body: rbody,
#       status_code: 200}} = get("/api/storage_auth")
#
#     {:ok, file} = File.read(file_name)
#
#     body = Poison.decode!(rbody)
#     url = "https:" <> body["url"]
#     form_data = body["form_data"]
#     attachment_url = url <> form_data["key"]
#     headers = [
#       {"Content-Type", "multipart/form-data"},
#       {"User-Agent", "FarmbotOS"}
#     ]
#     payload =
#       Enum.map(form_data, fn({key, value}) ->
#         if key == "file", do: {"file", file}, else: {key, value}
#       end)
#     Logger.info ">> #{attachment_url} Should hopefully exist shortly!"
#     url
#     |> HTTPoison.post({:multipart, payload}, headers)
#     |> finish_upload(attachment_url)
#   end
#
#   @spec finish_upload(any, binary) :: {:ok, HTTPoison.Response.t} | no_return
#
#   # We only want to upload if we get a 2XX response.
#   defp finish_upload({:ok, %HTTPoison.Response{status_code: s}}, attachment_url)
#   when s < 300 do
#     ctx   = Context.new()
#     [x, y, z] = Farmbot.BotState.get_current_pos(ctx)
#     meta      = %{x: x, y: y, z: z}
#     json      = Poison.encode! %{"attachment_url" => attachment_url,
#                                  "meta" => meta}
#     Farmbot.HTTP.post "/api/images", json
#   end
# end
