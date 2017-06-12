defmodule Farmbot.HTTP do
  @moduledoc """
    Farmbot HTTP adapter for accessing the world and farmbot web api easily.
  """
  use     GenServer
  alias   Farmbot.{Auth, Context, Token}
  alias   Farmbot.HTTP.{Response, Client, Error, Types, Helpers, Multipart}
  import  Helpers
  require Logger
  use     Farmbot.DebugLog
  use     Context, requires: [Auth]

  @version Mix.Project.config[:version]
  @target  Mix.Project.config[:target]

  @doc """
    Make an HTTP Request.
    * `context` is a Farmbot.Context
    * `method` can be an atom representing an HTTP verb
    * `url` is a binary url
    * `body` is a binary http payload
    * `opts` is a keyword list of options.
  """
  @spec request(Context.t,
    Types.method,
    Types.url,
    Types.body,
    Types.headers,
    Keyword.t) :: {:ok, Response.t} | {:error, term}
    # credo:disable-for-next-line
  def request(%Context{} = ctx, method, url, body, headers, opts) do
    {timeout, opts} = Keyword.pop(opts, :timeout, 30_000)
    r               = {:request, method, url, body, headers, opts}
    GenServer.call(ctx.http, r, timeout)
  end

  @spec request!(Context.t,
    Types.method,
    Types.url,
    Types.body,
    Types.headers,
    Keyword.t) :: Response.t | no_return
  # credo:disable-for-next-line
  def request!(%Context{} = ctx, method, url, body, headers, opts) do
    case request(ctx, method, url, body, headers, opts) do
      {:ok, response} -> response
      {:error, er} ->
        raise Error, message: "Http request #{inspect method} :" <>
          " #{inspect url} failed! #{inspect er}"
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
    Downloads a file to the filesystem.
    Will return the path to the downloaded file.
  """
  @spec download_file!(Context.t, Types.url, Path.t) :: Path.t
  def download_file!(%Context{} = ctx, url, path) do
    %Response{} = get! ctx, url, "", [], file: path
    path
  end

  @doc """
    Uploads a file to the API
  """
  @spec upload_file!(Context.t, Path.t) :: :ok | no_return
  def upload_file!(%Context{} = ctx, filename) do
    unless File.exists?(filename) do
      raise Error, message: "#{filename} not found"
    end

    %Response{status_code: 200, body: rbody} = get!(ctx, "/api/storage_auth")
    boundry                                  = Multipart.new_boundry()
    body                                     = Poison.decode!(rbody)
    file                                     = File.read!(filename)
    url                                      = "https:"  <> body["url"]
    form_data                                = body["form_data"]
    attachment_url                           = url <> form_data["key"]
    payload =
      Map.new(form_data, fn({key, value}) ->
        if key == "file",
          do: {"file", {Path.basename(filename), file}}, else: {key, value}
      end)
    real_payload = Multipart.format(payload, boundry)
    headers = [
      Multipart.multi_part_header(boundry),
      user_agent_header()
    ]
    ggl_response = post!(ctx, url, real_payload, headers, [])
    debug_log "#{attachment_url} should exist shortly."
    :ok = finish_upload!(ggl_response, ctx, attachment_url)
    :ok
  end

  defp finish_upload!(%Response{status_code: s}, %Context{} = ctx, atch_url)
  when is_2xx(s) do
    [x, y, z] = Farmbot.BotState.get_current_pos(ctx)
    meta      = %{x: x, y: y, z: z}
    json      = Poison.encode! %{"attachment_url" => atch_url,
                                 "meta" => meta}
    res       = post! ctx, "/api/images", json, [], []
    unless is_2xx(res.status_code) do
      raise Error, message: "Api refused upload: #{inspect res}"
    end
    :ok
  end

  defp finish_upload!(response, _ctx, _attachment_url) do
    raise Error, message: "bad status from GCS: #{inspect response}"
  end

  ## GenServer Stuff

  @doc """
    Start a HTTP adapter.
  """
  def start_link(%Context{} = ctx, opts) do
    GenServer.start_link(__MODULE__, ctx, opts)
  end

  def init(ctx) do
    Registry.register(Farmbot.Registry, Farmbot.Auth, [])
    Process.flag(:trap_exit, true)
    state = %{
      context: %{ctx | http: self()},
      token:   nil
    }
    {:ok, state}
  end

  def handle_call({:request, method, url, body, headers, opts}, from, state) do
    debug_log "Starting client."
    case url do
      "/api" <> _  ->
        debug_log "I think this is a farmbot api request: #{url}"
        r = {method, url, body, headers, opts}
        build_api_request(state.token, state.context, r, from)
      _ ->
        {:ok, pid} = Client.start_link(from, {method, url, body, headers}, opts)
        :ok        = Client.execute(pid)
    end
    {:noreply, state}
  end

  def handle_info({Auth, {:new_token, token}}, state) do
    {:noreply, %{state | token: token}}
  end

  def handle_info({Auth, :purge_token}, state),
    do: {:noreply, %{state | token: nil}}

  def handle_info({:EXIT, _old_client, _reason}, state) do
    debug_log "Client finished."
    {:noreply, state}
  end

  defp build_api_request(%Token{
      encoded: enc,
      unencoded: %{iss: server}},
    %Context{} = _ctx, request, from)
  do
    {method, slug, body, old_headers, opts} = request
    url                                     = "#{server}#{slug}"
    auth_header                             = {'Authorization', 'Bearer #{enc}'}
    uah                                     = user_agent_header()
    headers                                 = old_headers
                                              |> add_header(auth_header)
                                              |> add_header(uah)
    {:ok, pid} = Client.start_link(from, {method, url, body, headers}, opts)
    :ok        = Client.execute(pid)
  end

  defp build_api_request(_, _, _, from) do
    debug_log "Don't have a token. Not doing API request."
    GenServer.reply(from, {:error, :no_token})
    :ok
  end

  @spec add_header(Types.headers, Types.header) :: Types.headers
  defp add_header(headers, new), do: [new | headers]

  def user_agent_header do
    {'User-Agent', 'FarmbotOS/#{@version} (#{@target}) #{@target} ()'}
  end
end
