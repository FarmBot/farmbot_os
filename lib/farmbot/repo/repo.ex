defmodule Farmbot.Repo do
  use Farmbot.Logger
  alias Farmbot.Repo.Snapshot
  use Ecto.Repo,
    otp_app: :farmbot,
    adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]

  defdelegate sync(full \\ false), to: Farmbot.Repo.Worker
  defdelegate await_sync, to: Farmbot.Repo.Worker
  defdelegate register_sync_cmd(id, kind, body), to: Farmbot.System.ConfigStorage.SyncCmd

  alias Farmbot.HTTP
  alias Farmbot.Asset.{
    Device,
    FarmEvent,
    # GenericPointer,
    Peripheral,
    Point,
    Regimen,
    Sensor,
    Sequence,
    # ToolSlot,
    Tool
  }

  # A partial sync pulls all the sync commands from storage,
  # And applies them one by one.
  def partial_sync do
    Logger.debug 3, "Starting partial sync."
    old = snapshot()
    Farmbot.Repo.transaction fn() ->
      :ok
    end
    new = snapshot()
    diff = Snapshot.diff(old, new)
    Farmbot.Repo.Registry.dispatch(diff)
  end

  @doc """
  A full sync will clear the entire local data base
  and then redownload all data.
  """
  def full_sync do
    Logger.debug 3, "Starting full sync."
    old = snapshot()
    {:ok, results} = http_requests()
    Farmbot.Repo.transaction fn() ->
      :ok = clear_all_data()
      :ok = enter_into_repo(results)
      :ok
    end
    new = snapshot()
    diff = Snapshot.diff(old, new)
    Farmbot.Repo.Registry.dispatch(diff)
    :ok
  end

  def snapshot do
    Logger.debug 3, "Starting snapshot."
    {time, results} = :timer.tc(fn() ->
      Farmbot.Repo.all(Device) ++
      Farmbot.Repo.all(FarmEvent) ++
      # Farmbot.Repo.all(GenericPointer) ++
      Farmbot.Repo.all(Peripheral) ++
      Farmbot.Repo.all(Point) ++
      Farmbot.Repo.all(Regimen) ++
      Farmbot.Repo.all(Sensor) ++
      Farmbot.Repo.all(Sequence) ++
      # Farmbot.Repo.all(ToolSlot) ++
      Farmbot.Repo.all(Tool)
    end)
    Logger.debug 3, "Snapshot took: #{time}us."
    struct(Snapshot, [data: results])
    |> Snapshot.md5()
  end

  def clear_all_data do
    Farmbot.Repo.delete_all(Device)
    Farmbot.Repo.delete_all(FarmEvent)
    # Farmbot.Repo.delete_all(GenericPointer)
    Farmbot.Repo.delete_all(Peripheral)
    Farmbot.Repo.delete_all(Point)
    Farmbot.Repo.delete_all(Regimen)
    Farmbot.Repo.delete_all(Sensor)
    Farmbot.Repo.delete_all(Sequence)
    # Farmbot.Repo.delete_all(ToolSlot)
    Farmbot.Repo.delete_all(Tool)
    :ok
  end

  def http_requests do
    Logger.debug 3, "Starting HTTP requests."
    {time, results} = :timer.tc(fn() ->
      [
        Task.async(fn() -> {Device, HTTP.get!("/api/device.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {FarmEvent, HTTP.get!("/api/farm_events.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        # Task.async(fn() -> {GenericPointer, HTTP.get!("/api/generic_pointers.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {Peripheral, HTTP.get!("/api/peripherals.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {Point, HTTP.get!("/api/points.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {Regimen, HTTP.get!("/api/regimens.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {Sensor, HTTP.get!("/api/sensors.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {Sequence, HTTP.get!("/api/sequences.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        # Task.async(fn() -> {ToolSlot, HTTP.get!("/api/tool_slots.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
        Task.async(fn() -> {Tool, HTTP.get!("/api/tools.json") |> Map.fetch!(:body) |> Poison.decode!() } end),
      ]
      |> Enum.map(&Task.await(&1))
    end)
    Logger.debug 3, "HTTP requests took: #{time}us."
    {:ok, results}
  end

  def enter_into_repo(results) do
    Enum.map(results, &do_enter_into_repo(&1))
    :ok
  end

  defp do_enter_into_repo({Device, results}) do
    Device.changeset(struct(Device), results)
    |> Farmbot.Repo.insert!()
  end

  defp do_enter_into_repo({mod, results}) do
    Enum.map(results, fn(data) ->
      mod.changeset(struct(mod), data)
    end)
    |> Enum.map(&Farmbot.Repo.insert!(&1))
  end
end
