defmodule Farmbot.Repo do
  use Farmbot.Logger
  alias Farmbot.Repo.Snapshot
  use Ecto.Repo,
    otp_app: :farmbot,
    adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]

  defdelegate sync(verbosity \\ 1), to: Farmbot.Repo.Worker
  defdelegate await_sync, to: Farmbot.Repo.Worker

  import Farmbot.System.ConfigStorage, only: [destroy_all_sync_cmds: 0, destroy_sync_cmd: 1, all_sync_cmds: 0]
  import Farmbot.BotState, only: [set_sync_status: 1]

  alias Farmbot.HTTP
  alias Farmbot.Asset.{
    Device,
    FarmEvent,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool
  }

  @doc """
  A full sync will clear the entire local data base
  and then redownload all data.
  """
  def full_sync(verbosity \\ 1) do
    IO.puts "full"
    Logger.busy verbosity, "Syncing"
    set_sync_status(:syncing)
    old = snapshot()
    {:ok, results} = http_requests()
    Farmbot.Repo.transaction fn() ->
      :ok = Farmbot.Asset.clear_all_data()
      :ok = enter_into_repo(results)
    end
    Farmbot.Repo.SeedDB.run()
    new = snapshot()
    diff = Snapshot.diff(old, new)
    Farmbot.Repo.Registry.dispatch(diff)
    destroy_all_sync_cmds()
    set_sync_status(:synced)
    Logger.success verbosity, "Synced"
    :ok
  end

  def fragment_sync(verbosity \\ 1) do
    IO.puts "fragment"
    Logger.busy verbosity, "Syncing"
    set_sync_status(:syncing)
    old = snapshot()
    all_sync_cmds = all_sync_cmds()

    Farmbot.Repo.transaction fn() ->
      for cmd <- all_sync_cmds do
        apply_sync_cmd(cmd)
      end
    end

    new = snapshot()
    diff = Snapshot.diff(old, new)
    Farmbot.Repo.Registry.dispatch(diff)
    destroy_all_sync_cmds()
    set_sync_status(:synced)
    Logger.success verbosity, "Synced"
  end

  def snapshot do
    results = Farmbot.Repo.all(Device) ++
    Farmbot.Repo.all(FarmEvent) ++
    Farmbot.Repo.all(Peripheral) ++
    Farmbot.Repo.all(PinBinding) ++
    Farmbot.Repo.all(Point) ++
    Farmbot.Repo.all(Regimen) ++
    Farmbot.Repo.all(Sensor) ++
    Farmbot.Repo.all(Sequence) ++
    Farmbot.Repo.all(Tool)

    struct(Snapshot, [data: results])
    |> Snapshot.md5()
  end

  def http_requests do
    Logger.debug 3, "Starting HTTP requests."
    {time, results} = :timer.tc(fn() ->
      [
        Task.async(fn() -> {Device, HTTP.get!("/api/device.json") |> Map.fetch!(:body) |> Poison.decode!(as: struct(Device))} end),
        Task.async(fn() -> {FarmEvent, HTTP.get!("/api/farm_events.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(FarmEvent)])} end),
        Task.async(fn() -> {Peripheral, HTTP.get!("/api/peripherals.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Peripheral)])} end),
        Task.async(fn() -> {PinBinding, HTTP.get!("/api/pin_bindings.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(PinBinding)])} end),
        Task.async(fn() -> {Point, HTTP.get!("/api/points.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Point)])} end),
        Task.async(fn() -> {Regimen, HTTP.get!("/api/regimens.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Regimen)])} end),
        Task.async(fn() -> {Sensor, HTTP.get!("/api/sensors.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Sensor)])} end),
        Task.async(fn() -> {Sequence, HTTP.get!("/api/sequences.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Sequence)])} end),
        Task.async(fn() -> {Tool, HTTP.get!("/api/tools.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Tool)])} end),
      ]
      |> Enum.map(&Task.await(&1))
    end)
    Logger.debug 3, "HTTP requests took: #{time}us."
    {:ok, results}
  end

  def enter_into_repo(results) do
    Enum.each(results, &do_enter_into_repo(&1))
    :ok
  end

  defp do_enter_into_repo({Device, device}) do
    Device.changeset(device, %{})
    |> Farmbot.Repo.insert!()
  end

  defp do_enter_into_repo({mod, results}) do
    Enum.map(results, fn(data) ->
      mod.changeset(data, %{})
    end)
    |> Enum.map(&Farmbot.Repo.insert!(&1))
  end

  def apply_sync_cmd(cmd) do
    mod = Module.concat(["Farmbot", "Asset", cmd.kind])
    if Code.ensure_loaded?(mod) do
      set_sync_status(:syncing)
      Logger.debug(3, "Syncing #{cmd.kind}")
      do_apply_sync_cmd(cmd)
      set_sync_status(:synced)
    else
      Logger.warn(3, "Unknown module: #{mod} #{inspect(cmd)}")
    end
    destroy_sync_cmd(cmd)
  end

  # When `body` is nil, it means an object was deleted.
  def do_apply_sync_cmd(%{body: nil, remote_id: id, kind: kind}) do
    mod = Module.concat(["Farmbot", "Asset", kind])
    case Farmbot.Repo.get(mod, id) do
      nil ->
        :ok

      existing ->
        Farmbot.Repo.delete!(existing)
        :ok
    end
  end

  def do_apply_sync_cmd(%{body: obj, remote_id: id, kind: kind}) do
    not_struct = strip_struct(obj)
    mod = Module.concat(["Farmbot", "Asset", kind])
    # We need to check if this object exists in the database.
    case Farmbot.Repo.get(mod, id) do
      # If it does not, just return the newly created object.
      nil ->
        change = mod.changeset(struct(mod, not_struct), not_struct)
        Farmbot.Repo.insert!(change)
        :ok
      # if there is an existing record, copy the ecto  meta from the old
      # record. This allows `insert_or_update` to work properly.
      existing ->
        Ecto.Changeset.change(existing, not_struct)
        |> Farmbot.Repo.update!
        :ok
    end
  end

  defp strip_struct(%{__struct__: _, __meta__: _} = struct) do
    Map.from_struct(struct) |> Map.delete(:__meta__)
  end

  defp strip_struct(already_map), do: already_map
end
