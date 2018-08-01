defmodule Farmbot.HTTP do
  @moduledoc "Wraps an HTTP Adapter."

  # credo:disable-for-this-file Credo.Check.Refactor.FunctionArity

  use GenServer
  alias Farmbot.HTTP.{Adapter, Error, Response}
  alias Farmbot.JSON

  @adapter Application.get_env(:farmbot_ext, :behaviour)[:http_adapter]
  @adapter || raise("No http adapter.")

  @typep method :: Adapter.method
  @typep url :: Adapter.url
  @typep body :: Adapter.body
  @typep headers :: Adapter.headers
  @typep opts :: Adapter.opts

  alias Farmbot.Asset.{
    Device,
    FarmEvent,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool,
  }

  def device, do: fetch_and_decode("/api/device.json", Device)
  def farm_events, do: fetch_and_decode("/api/farm_events.json", FarmEvent)
  def peripherals, do: fetch_and_decode("/api/peripherals.json", Peripheral)
  def pin_bindings, do: fetch_and_decode("/api/pin_bindings.json", PinBinding)
  def points, do: fetch_and_decode("/api/points.json", Point)
  def regimens, do: fetch_and_decode("/api/regimens.json", Regimen)
  def sensors, do: fetch_and_decode("/api/sensors.json", Sensor)
  def sequences, do: fetch_and_decode("/api/sequences.json", Sequence)
  def tools, do: fetch_and_decode("/api/tools.json", Tool)

  def fetch_and_decode(url, kind) do
    url
    |> get!()
    |> Map.fetch!(:body)
    |> JSON.decode!()
    |> Farmbot.Asset.to_asset(kind)
  end

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
  @spec request(method, url, body, headers, opts)
    :: {:ok, Response.t} | {:error, term}
  def request(method, url, body \\ "", headers \\ [], opts \\ [])

  def request(method, url, body, headers, opts) do
    call = {:request, method, url, body, headers, opts}
    GenServer.call(__MODULE__, call, :infinity)
  end

  @doc "Same as `request/5` but raises."
  @spec request!(method, url, body, headers, opts) :: Response.t | no_return
  def request!(method, url, body \\ "", headers \\ [], opts \\ [])

  def request!(method, url, body, headers, opts) do
    case request(method, url, body, headers, opts) do
      {:ok, %Response{status_code: code} = resp}
        when code > 199 and code < 300 -> resp

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
  @spec post!(url, body, headers, opts) :: Response.t | no_return
  def post!(url, body, headers \\ [], opts \\ [])

  def post!(url, body, headers, opts) do
    request!(:post, url, body, headers, opts)
  end

  @doc "HTTP PUT request."
  @spec put(url, body, headers, opts) :: {:ok, Response.t} | {:error, term}
  def put(url, body, headers \\ [], opts \\ [])

  def put(url, body, headers, opts) do
    request(:put, url, body, headers, opts)
  end

  @doc "Same as `put/4` but raises."
  @spec put!(url, body, headers, opts) :: Response.t | no_return
  def put!(url, body, headers \\ [], opts \\ [])

  def put!(url, body, headers, opts) do
    request!(:put, url, body, headers, opts)
  end

  @doc "HTTP DELETE request."
  @spec delete(url, headers, opts) :: {:ok, Response.t} | {:error, term}
  def delete(url, headers \\ [], opts \\ [])

  def delete(url, headers, opts) do
    request!(:delete, url, "", headers, opts)
  end

  @doc "Same as `delete/3` but raises."
  @spec delete!(url, headers, opts) :: Response.t | no_return
  def delete!(url, headers \\ [], opts \\ [])

  def delete!(url, headers, opts) do
    request!(:delete, url, "", headers, opts)
  end

  @doc "Download a file to the filesystem."
  def download_file(url,
                    path,
                    progress_callback \\ nil,
                    payload \\ "",
                    headers \\ [],
                    stream_fun \\ nil)

  def download_file(url, path, progress_callback, payload, hddrs, stream_fun) do
    opts = {url, path, progress_callback, payload, hddrs, stream_fun}
    call = {:download_file, opts}
    GenServer.call(__MODULE__, call, :infinity)
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
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:ok, adapter} = @adapter.start_link()
    Process.link(adapter)
    {:ok, %{adapter: adapter}}
  end

  def handle_call({:request, _, _, _, _, _} = req, _from, state) do
    {:request, method, url, body, headers, opts} = req
    args = [state.adapter, method, url, body, headers, opts]
    res = case apply(@adapter, :request, args) do
      {:ok, %Response{}} = res -> res
      {:error, _} = res -> res
    end
    {:reply, res, state}
  end

  def handle_call({:download_file, call}, _from, %{adapter: adapter} = state) do
    {url, path, progress_callback, payload, headers, stream_fun} = call
    args = [adapter, url, path, progress_callback, payload, headers, stream_fun]
    res = case apply(@adapter, :download_file, args) do
      {:ok, _} = res -> res
      {:error, _} = res -> res
    end
    {:reply, res, state}
  end

  def handle_call({:upload_file, {path, meta}}, _from, state) do
    meta_arg = meta || %{x: -1, y: -1, z: -1}
    args = [state.adapter, path, meta_arg]
    res = case apply(@adapter, :upload_file, args) do
      {:ok, _} = res -> res
      {:error, _} = res -> res
    end
    {:reply, res, state}
  end
end
