defmodule Farmbot.Repo do
  use Farmbot.Logger
  alias Farmbot.Repo.Snapshot
  use Ecto.Repo,
    otp_app: :farmbot,
    adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]

  defdelegate sync, to: Farmbot.Repo.Worker
  defdelegate await_sync, to: Farmbot.Repo.Worker

  import Farmbot.System.ConfigStorage, only: [destroy_all_sync_cmds: 0]
  import Farmbot.BotState, only: [set_sync_status: 1]

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

  @doc """
  A full sync will clear the entire local data base
  and then redownload all data.
  """
  def full_sync do
    Logger.debug 3, "Starting full sync."
    set_sync_status(:syncing)
    old = snapshot()
    {:ok, results} = http_requests()
    Farmbot.Repo.transaction fn() ->
      :ok = clear_all_data()
      :ok = enter_into_repo(results)
    end
    new = snapshot()
    diff = Snapshot.diff(old, new)
    Farmbot.Repo.Registry.dispatch(diff)
    destroy_all_sync_cmds()
    set_sync_status(:synced)
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
    set_sync_status(:sync_now)
    :ok
  end

  def http_requests do
    Logger.debug 3, "Starting HTTP requests."
    {time, results} = :timer.tc(fn() ->
      [
        Task.async(fn() -> {Device, HTTP.get!("/api/device.json") |> Map.fetch!(:body) |> Poison.decode!(as: struct(Device)) } end),
        Task.async(fn() -> {FarmEvent, HTTP.get!("/api/farm_events.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(FarmEvent)]) } end),
        # Task.async(fn() -> {GenericPointer, HTTP.get!("/api/generic_pointers.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(GenericPointer)]) } end),
        Task.async(fn() -> {Peripheral, HTTP.get!("/api/peripherals.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Peripheral)]) } end),
        Task.async(fn() -> {Point, HTTP.get!("/api/points.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Point)]) } end),
        Task.async(fn() -> {Regimen, HTTP.get!("/api/regimens.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Regimen)]) } end),
        Task.async(fn() -> {Sensor, HTTP.get!("/api/sensors.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Sensor)]) } end),
        Task.async(fn() -> {Sequence, HTTP.get!("/api/sequences.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Sequence)]) } end),
        # Task.async(fn() -> {ToolSlot, HTTP.get!("/api/tool_slots.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(ToolSlot)]) } end),
        Task.async(fn() -> {Tool, HTTP.get!("/api/tools.json") |> Map.fetch!(:body) |> Poison.decode!(as: [struct(Tool)]) } end),
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
      Logger.debug(3, "Applying sync_cmd (#{mod}): insert_or_update")
      do_apply_sync_cmd(cmd)
      set_sync_status(:sync_now)
    else
      Logger.warn(3, "Unknown module: #{mod} #{inspect(cmd)}")
    end
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
        mod.changeset(struct(mod), not_struct)
        |> Farmbot.Repo.insert!
        :ok
      # if there is an existing record, copy the ecto  meta from the old
      # record. This allows `insert_or_update` to work properly.
      existing ->
        mod.changeset(existing, not_struct)
        |> Farmbot.Repo.update!
        :ok
    end
  end

  defp strip_struct(%{__struct__: _, __meta__: _} = struct) do
    Map.from_struct(struct) |> Map.delete(:__meta__)
  end

  defp strip_struct(already_map), do: already_map
end
