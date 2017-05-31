defmodule Farmbot.HTTP do
  use GenServer
  alias Farmbot.{Auth, Context, Token}
  alias Farmbot.HTTP.{Response, Client, Error}
  require Logger
  use Farmbot.DebugLog

  @version Mix.Project.config[:version]
  @target Mix.Project.config[:target]

  @doc """
    Make an HTTP Request.
    * `context` is a Farmbot.Context
    * `method` can be an atom representing an HTTP verb
    * `url` is a binary url
    * `body` is a binary http payload
    * `opts` is a keyword list of options.
  """
  def request(%Context{} = ctx, method, url, body, headers, opts) do
    GenServer.call(ctx.http, {:request, method, url, body, headers, opts}, 30_000)
  end

  def request!(%Context{} = ctx, method, url, body, headers, opts) do
    case request(ctx, method, url, body, headers, opts) do
      {:ok, response} -> response
      {:error, er} ->
        raise Error, "Http request #{inspect method} : #{inspect url} failed! #{inspect er}"
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

  @doc """
    Downloads a file to the filesystem
  """
  def download_file!(%Context{} = ctx, url, path) do
    raise "Failed to download file: #{inspect :todo}"
  end

  @doc """
    Uploads a file to the API
  """
  def upload_file!(%Context{} = _ctx, _url) do
    raise "Uplaoding to the API is still TODO"
  end

  ## GenServer Stuff

  @doc """
    Start a HTTP adapter.
  """
  def start_link(%Context{} = ctx, opts) do
    GenServer.start_link(__MODULE__, ctx, opts)
  end

  def init(ctx) do
    Process.flag(:trap_exit, true)
    state = %{
      context: %{ctx | http: self()},
    }
    {:ok, state}
  end

  def handle_call({:request, method, url, body, headers, opts}, from, state) do
    debug_log "Starting client."
    {:ok, _pid} = Client.start_link(from, {method, url, body, headers}, opts)
    {:noreply, state}
  end

  def handle_info({:EXIT, _old_client, _reason}, state) do
    debug_log "Client finished."
    {:noreply, state}
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
