defmodule FarmbotOS.DirtyWorker do
  @moduledoc "Handles uploading/downloading of data from the APIFetcher."
  alias FarmbotOS.Asset.{Private, Repo}

  alias FarmbotOS.{
    API,
    DirtyWorker,
    APIFetcher
  }

  import API.View, only: [render: 2]

  require Logger
  require FarmbotOS.Logger
  use GenServer
  @timeout 1000
  # these resources can't be accessed by `id`.
  @singular [
    FarmbotOS.Asset.Device,
    FarmbotOS.Asset.FirmwareConfig,
    FarmbotOS.Asset.FbosConfig
  ]
  @stale_warning "Stale data detected. Please check internet connection and re-sync."

  @doc false
  def child_spec(module) when is_atom(module) do
    %{
      id: {DirtyWorker, module},
      start: {__MODULE__, :start_link, [[module: module, timeout: @timeout]]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc "Start an instance of a DirtyWorker"
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    module = Keyword.fetch!(args, :module)
    FarmbotOS.Time.send_after(self(), :do_work, @timeout)
    {:ok, %{module: module}}
  end

  @impl GenServer
  def handle_info(:do_work, %{module: module} = state) do
    FarmbotOS.Time.sleep(@timeout)
    maybe_resync(module)
    maybe_upload(module)
    FarmbotOS.Time.send_after(self(), :do_work, @timeout)
    {:noreply, state}
  end

  def work(dirty, module) do
    # Go easy on the API
    FarmbotOS.Time.sleep(@timeout)
    response = http_request(dirty, module)
    handle_http_response(dirty, module, response)
  end

  defp http_request(%{id: nil} = dirty, module) do
    path = module.path()
    data = render(module, dirty)
    APIFetcher.post(APIFetcher.client(), path, data)
  end

  defp http_request(dirty, module) when module in @singular do
    path = module.path()
    data = render(module, dirty)
    APIFetcher.patch(APIFetcher.client(), path, data)
  end

  defp http_request(dirty, module) do
    path = Path.join(module.path(), to_string(dirty.id))
    data = render(module, dirty)
    APIFetcher.patch(APIFetcher.client(), path, data)
  end

  # This is a fix for a race condition. The root cause is unknown
  # as of 18 May 2020. The problem is that records are marked
  # dirty _before_ the dirty data is saved. That means that FBOS
  # knows a record has changed, but for a brief moment, it only
  # has the old copy of the record (not the changes).
  # Because of this race condition,
  # The race condition:
  #
  # * Is nondeterministic
  # * Happens frequently when running many MARK AS steps in
  #   one go.
  # * Happens frequently when Erlang VM only has one thread
  #    * Ie: `iex --erl '+S 1 +A 1' -S mix`
  # * Happens frequently when @timeout is decreased to `1`.
  #
  # This function PREVENTS CORRUPTION OF API DATA. It can be
  # removed once the root cause of the data race is
  # determined.
  #
  #   - RC 18 May 2020
  def has_race_condition?(module, list) do
    Enum.find_value(list, fn item ->
      # If we query the data and it is not an exact match
      # of the data we have, something is wrong.
      race? = item != Repo.get_by(module, local_id: item.local_id)

      if race? do
        # Pause until the race condition goes away.
        FarmbotOS.Time.sleep(@timeout * 8)
        true
      else
        # This is OK! We expect the data to equal itself.
        # There is no race condition here.
        false
      end
    end)
  end

  def do_stale_recovery(timeout) do
    FarmbotOS.Logger.error(4, @stale_warning)
    Private.recover_from_row_lock_failure()
    FarmbotOS.Celery.SysCallGlue.sync()
    FarmbotOS.Time.sleep(timeout * 10)
    true
  end

  def maybe_resync(timeout \\ @timeout) do
    if Private.any_stale?() do
      do_stale_recovery(timeout)
      true
    else
      false
    end
  end

  def maybe_upload(module) do
    list = Enum.uniq(Private.list_dirty(module) ++ Private.list_local(module))

    unless has_race_condition?(module, list) do
      Enum.map(list, fn dirty -> work(dirty, module) end)
    end
  end

  # Valid data
  def handle_http_response(dirty, module, {:ok, %{status: s, body: body}})
      when s > 199 and s < 300 do
    dirty |> module.changeset(body) |> finalize(module)
  end

  def handle_http_response(dirty, _module, {:ok, %{status: s}}) when s == 409 do
    Private.mark_stale!(dirty)
    do_stale_recovery(@timeout)
  end

  # Invalid data
  def handle_http_response(dirty, module, {:ok, %{status: s, body: %{} = body}})
      when s > 399 and s < 500 do
    FarmbotOS.Logger.error(2, "HTTP Error #{s}. #{inspect(body)}")
    changeset = module.changeset(dirty)

    Enum.reduce(body, changeset, fn {key, val}, changeset ->
      Ecto.Changeset.add_error(changeset, key, val)
    end)
    |> finalize(module)
  end

  # Invalid data, but the API didn't say why
  def handle_http_response(dirty, module, {:ok, %{status: s, body: _body}})
      when s > 399 and s < 500 do
    FarmbotOS.Logger.error(2, "HTTP Error #{s}. #{inspect(dirty)}")

    module.changeset(dirty)
    |> Map.put(:valid?, false)
    |> finalize(module)
  end

  # HTTP Error. (500, network error, timeout etc.)
  def handle_http_response(dirty, module, error) do
    m = inspect(module)
    e = inspect(error)
    id = Repo.encode_local_id(dirty.local_id)
    msg = "[#{m} #{id} #{inspect(self())}] HTTP Error: #{e}"
    Logger.error(msg)
    error
  end

  # If the changeset was valid, update the record.
  def finalize(%{valid?: true} = changeset, _module) do
    Private.mark_clean!(Repo.update!(changeset))
    :ok
  end

  def finalize(%{valid?: false, data: data} = changeset, module) do
    message =
      Enum.map(changeset.errors, fn
        {key, {msg, _meta}} when is_binary(key) -> "\t#{key}: #{msg}"
        {key, msg} when is_binary(key) -> "\t#{key}: #{msg}"
      end)
      |> Enum.join("\n")

    FarmbotOS.Logger.error(3, "Failed to sync: #{module} \n #{message}")
    _ = Repo.delete!(data)
    :ok
  end
end
