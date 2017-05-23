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
    AsyncRedirect
  }

    @version Mix.Project.config[:version]
    @target Mix.Project.config[:target]
    @twenty_five_seconds 25_000
    @http_config [
      ssl: [versions: [:'tlsv1.2']],
      recv_timeout: @twenty_five_seconds,
      timeout: @twenty_five_seconds,
      follow_redirect: true
    ]

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

  def get(context, url, body \\ "", headers \\ [], opts \\ [])
  def get(%Context{} = ctx, url, body, headers, opts), do: request(ctx, :get, url, body, headers, opts)

  def post(context, url, body \\ "", headers \\ [], opts \\ [])
  def post(%Context{} = ctx, url, body, headers, opts), do: request(ctx, :post, url, body, headers, opts)

  ## GenServer Stuff

  @doc """
    Start a HTTP client
  """
  def start_link(%Context{} = ctx, opts) do
    GenServer.start_link(__MODULE__, ctx, opts)
  end

  def init(ctx) do
    maybe_token =
      case Auth.get_token(ctx.auth) do
        {:ok, token} -> token
        _ -> nil
      end
    state = %{
      context: %{ctx | http: self()},
      token:   maybe_token,
      requests: %{}
    }
    {:ok, state}
  end

  defp empty_request do
    %{
      status_code: nil,
      body: "",
      headers: [],
    }
  end

  defp create_request({:request, method, url, body, headers, opts} = request, from, state) do
    {save_to_file, opts} = Keyword.pop(opts, :to_file, false)
    new_opts = Keyword.put(opts, :stream_to, state.context.http)
    options = Keyword.merge(@http_config, new_opts)
    %AsyncResponse{id: ref} = HTTPoison.request!(method, url, body, headers, options)
    r_map = {from, request, empty_request()}
    requests = Map.put(state.requests, ref, r_map)
    debug_log "Creating request: #{inspect ref}"
    %{state | requests: requests}
  end

  def handle_call({:request, method, url, body, headers, opts} = request, from, state) do
    new_state = create_request(request, from, state)
    {:noreply, new_state}
  end

  def handle_info(%AsyncStatus{id: ref, code: code}, state) do
    request = state.requests[ref]
    case request do
      {_from, _request, map} ->
        new_request = %{map | status_code: code}
        new_requests = %{state.requests | ref => new_request}
        %{state | requests: new_requests}
      _ ->
        debug_log "Unrecognized ref (Status): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncHeaders{id: ref, headers: headers}, state) do
    request = state.requests[ref]
    case request do
      {_from, _request, map} ->
        new_request  = %{request | headers: headers}
        new_requests = %{state.requests | ref => new_request}
        %{state | requests: new_requests}
      _ ->
        debug_log "Unrecognized ref (Headers): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncChunk{id: ref, chunk: chunk}, state) do
    request = state.requests[ref]
    case request do
      {_from, _request, map} ->
        new_request = %{request | body: request.body <> chunk}
        new_requests = %{state.requests | ref => new_request}
        %{state | requests: new_requests}
      _ ->
        debug_log "Unrecognized ref (Chunk): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncEnd{id: ref}     = info, state) do
    request = state.requests[ref]
    case request do
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
        GenServer.reply(from, reply)
        new_requests = Map.delete(state.requests, ref)
        {:noreply, %{state | requests: new_requests}}
      _ ->
        debug_log "Unrecognized ref (End): #{inspect ref}"
        {:noreply, state}
    end
  end

  def handle_info(%AsyncRedirect{id: ref, to: new_url} = red, state) do
    request = state.requests[ref]
    case request do
      {from, {:request, method, _url, body, headers, opts},
      %{
        status_code: _code,
        headers: _headers,
        body: _body
      }} ->

        # require IEx
        # IEx.pry

        debug_log "Following redirect #{inspect ref}"
        new_request  = {:request, method, new_url, body, headers, opts}
        new_requests = state.requests |> Map.delete(ref)
        new_state    = %{state | requests: new_requests}
        new_state_1  = create_request(new_request, from, state)
        debug_log "new_state1: #{inspect new_state_1}"
        {:noreply, new_state_1}
      _ ->
        debug_log "Unrecognized ref (Redirect): #{inspect ref}"
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
