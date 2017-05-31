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
        raise Error, message: "Http request #{inspect method} : #{inspect url} failed! #{inspect er}"
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
    {:ok, pid} = Client.start_link(from, {method, url, body, headers}, opts)
    :ok        = Client.execute(pid)
    {:noreply, state}
  end

  def handle_info({:EXIT, _old_client, _reason}, state) do
    debug_log "Client finished."
    {:noreply, state}
  end
end
