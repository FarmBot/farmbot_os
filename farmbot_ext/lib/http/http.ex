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

  @device_fields ~W(id name timezone)
  def device, do: fetch_and_decode("/api/device.json", @device_fields, Device)

  @farm_events_fields ~W(calendar end_time executable_id executable_type id repeat start_time time_unit)
  def farm_events, do: fetch_and_decode("/api/farm_events.json", @farm_events_fields, FarmEvent)

  @peripherals_fields ~W(id label mode pin)
  def peripherals, do: fetch_and_decode("/api/peripherals.json", @peripherals_fields, Peripheral)

  @pin_bindings_fields ~W(id pin_num sequence_id special_action)
  def pin_bindings, do: fetch_and_decode("/api/pin_bindings.json", @pin_bindings_fields, PinBinding)

  @points_fields ~W(id meta name pointer_type tool_id x y z)
  def points, do: fetch_and_decode("/api/points.json", @points_fields, Point)

  @regimens_fields ~W(farm_event_id id name regimen_items)
  def regimens, do: fetch_and_decode("/api/regimens.json", @regimens_fields, Regimen)

  @sensors_fields ~W(id label mode pin)
  def sensors, do: fetch_and_decode("/api/sensors.json", @sensors_fields, Sensor)

  @sequences_fields ~W(args body id kind name)
  def sequences, do: fetch_and_decode("/api/sequences.json", @sequences_fields, Sequence)

  @tools_fields ~W(id name)
  def tools, do: fetch_and_decode("/api/tools.json", @tools_fields, Tool)

  def fetch_and_decode(url, fields, kind) do
    url
    |> get!()
    |> Map.fetch!(:body)
    |> JSON.decode!()
    |> resource_decode(fields, kind)
  end

  def resource_decode(data, fields, kind) when is_list(data),
    do: Enum.map(data, &resource_decode(&1, fields, kind))

  def resource_decode(data, fields, kind) do
    data
    |> Map.take(fields)
    |> Enum.map(&string_to_atom/1)
    |> into_struct(kind)
  end

  def string_to_atom({k, v}), do: {String.to_atom(k), v}
  def into_struct(data, kind), do: struct(kind, data)

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
