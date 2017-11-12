defmodule Farmbot.HTTP do
  @moduledoc "Wraps an HTTP Adapter."
  use GenServer
  alias Farmbot.HTTP.{Adapter, Error, Response}

  @adapter Application.get_env(:farmbot, :behaviour)[:http_adapter] || raise("No http adapter.")

  @typep method :: Adapter.method
  @typep url :: Adapter.url
  @typep body :: Adapter.body
  @typep headers :: Adapter.headers
  @typep opts :: Adapter.opts

  @doc """
  Make an http request. Will not raise.
  * `method` - can be any http verb
  * `url`    - fully formatted url or an api slug.
  * `body`   - body can be any of:
    * binary
    * `{:multipart, [{binary_key, binary_value}]}`
  * headers  - `[{binary_key, binary_value}]`
  * opts     - Keyword opts to be passed to adapter (hackney/httpoison)
    * `file` - option to  be passed if the output should be saved to a file.
  """
  @spec request(method, url, body, headers, opts) :: {:ok, Response.t} | {:error, term}
  def request(method, url, body \\ "", headers \\ [], opts \\ [])

  def request(method, url, body, headers, opts) do
    GenServer.call(__MODULE__, {:request, method, url, body, headers, opts}, :infinity)
  end

  @doc "Same as `request/5` but raises."
  @spec request!(method, url, body, headers, opts) :: Response.t | no_return
  def request!(method, url, body \\ "", headers \\ [], opts \\ [])

  def request!(method, url, body, headers, opts) do
    case request(method, url, body, headers, opts) do
      {:ok, %Response{status_code: code} = resp} when code > 199 and code < 300 -> resp
      {:ok, %Response{} = resp} -> raise Error, resp

      {:error, reason} -> raise Error, reason
    end
  end

  @doc "HTTP GET request."
  @spec get(url, headers, opts) :: {:ok, Response.t}  | {:error, term}
  def get(url, headers \\ [], opts \\ [])

  def get(url, headers, opts) do
    request(:get, url, "", headers, opts)
  end

  @doc "Same as `get/3` but raises."
  @spec get!(url, headers, opts) :: Response.t | no_return
  def get!(url, headers \\ [], opts \\ [])

  def get!(url, headers, opts) do
    request!(:get, url, "", headers, opts)
  end

  @doc "HTTP POST request."
  @spec post(url, headers, opts) :: {:ok, Response.t}  | {:error, term}
  def post(url, body, headers \\ [], opts \\ [])

  def post(url, body, headers, opts) do
    request(:post, url, body, headers, opts)
  end

  @doc "Same as `post/4` but raises."
  @spec post!(url, headers, opts) :: Response.t | no_return
  def post!(url, body, headers \\ [], opts \\ [])

  def post!(url, body, headers, opts) do
    request!(:post, url, body, headers, opts)
  end

  def put(url, body, headers \\ [], opts \\ [])

  def put(url, body, headers, opts) do
    request(:put, url, body, headers, opts)
  end

  @doc "Download a file to the filesystem."
  def download_file(url, path, progress_callback \\ nil, payload \\ "", headers \\ [])

  def download_file(url, path, progress_callback, payload, headers) do
    GenServer.call(__MODULE__, {:download_file, {url, path, progress_callback, payload, headers}}, :infinity)
  end

  @doc "Upload a file to FB storage."
  def upload_file(path, meta \\ nil) do
    if File.exists?(path) do
      GenServer.call(__MODULE__, {:upload_file, {path, meta}}, :infinity)
    else
      {:error, "#{path} not found"}
    end
  end

  @doc "Start HTTP Services."
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, adapter} = @adapter.start_link()
    Process.link(adapter)
    {:ok, %{adapter: adapter}}
  end

  def handle_call({:request, method, url, body, headers, opts}, _from, %{adapter: adapter} = state) do
    res = case @adapter.request(adapter, method, url, body, headers, opts) do
      {:ok, %Response{}} = res -> res
      {:error, _} = res -> res
    end
    {:reply, res, state}
  end

  def handle_call({:download_file, {url, path, progress_callback, payload, headers}}, _from, %{adapter: adapter} = state) do
    res = case @adapter.download_file(adapter, url, path, progress_callback, payload, headers) do
      {:ok, _} = res -> res
      {:error, _} = res -> res
    end
    {:reply, res, state}
  end

  def handle_call({:upload_file, {path, meta}}, _from, %{adapter: adapter} = state) do
    res = case @adapter.upload_file(adapter, path, meta || %{x: -1, y: -1, z: -1}) do
      {:ok, _} = res -> res
      {:error, _} = res -> res
    end
    {:reply, res, state}
  end
end
