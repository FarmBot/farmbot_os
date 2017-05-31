defmodule Farmbot.HTTP do
  use GenServer
  alias Farmbot.{Auth, Context, Token}
  alias Farmbot.HTTP.{Response, Client}
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
  def request(context, method, url, body \\ "", headers \\ [], opts \\ [])

  def request(%Context{} = ctx, method, url, body, headers, opts) do
    GenServer.call(ctx.http, {:request, method, url, body, headers, opts}, 30_000)
  end

  def request!(context, method, url, body \\ "", headers \\ [], opts \\ [])
  def request!(%Context{} = ctx, method, url, body, headers, opts) do
    debug_log "doing request!"
    case request(ctx, method, url, body, headers, opts) do
      {:ok, response} -> response
      {:error, er} ->
        raise "Http request #{inspect method} : #{inspect url} failed! #{inspect er}"
    end
  end

  @doc """
    HTTP GET.
  """
  def get(context, url, body \\ "", headers \\ [], opts \\ [])
  def get(%Context{} = ctx, url, body, headers, opts), do: request(ctx, :get, url, body, headers, opts)

  def post(context, url, body \\ "", headers \\ [], opts \\ [])
  def post(%Context{} = ctx, url, body, headers, opts) do
    debug_log "doing http post: \n" <> body
    request(ctx, :post, url, body, headers, opts)
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
