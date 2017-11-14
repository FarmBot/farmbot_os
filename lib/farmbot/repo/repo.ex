defmodule Farmbot.Repo do
  @moduledoc "Wrapper between two repos."

  use GenServer
  use Farmbot.Logger

  alias Farmbot.Repo.{
    Device,
    FarmEvent,
    Peripheral,
    Point,
    Regimen,
    Sequence,
    Tool
  }

  alias Farmbot.BotState
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.SyncCmd

  @singular_resources [Device]

  @doc "Fetch the current repo."
  def current_repo do
    GenServer.call(__MODULE__, :current_repo)
  end

  @doc "Fetch the non current repo."
  def other_repo do
    GenServer.call(__MODULE__, :other_repo)
  end

  @doc "Flip the repos."
  def flip() do
    GenServer.call(__MODULE__, :flip)
  end

  @doc "Register a diff to be stored until a flip."
  def register_sync_cmd(remote_id, kind, body) do
    GenServer.call(__MODULE__, {:register_sync_cmd, remote_id, kind, body}, :infinity)
  end

  @doc false
  def start_link(repos) do
    GenServer.start_link(__MODULE__, repos, [name: __MODULE__])
  end

  def init([repo_a, repo_b]) do
    # Delete any old sync cmds.
    ConfigStorage.delete_all SyncCmd

    needs_hard_sync = if ConfigStorage.get_config_value(:bool, "settings", "first_sync") || auto_sync?() do
      do_sync_all_resources(repo_a)
      do_sync_all_resources(repo_b)
      ConfigStorage.update_config_value(:bool, "settings", "first_sync", false)
      BotState.set_sync_status(:synced)
      false
    else
      BotState.set_sync_status(:sync_now)
      true
    end

    repos = case ConfigStorage.get_config_value(:string, "settings", "current_repo") do
      "A" -> [repo_a, repo_b]
      "B" -> [repo_b, repo_a]
    end

    # Copy configs
    [current, _] = repos
    copy_configs(current)
    {:ok, %{repos: repos, needs_hard_sync: needs_hard_sync}}
  end

  defp copy_configs(repo) do
    case repo.one(Device) do
      nil -> :ok
      %{timezone: tz} ->
        ConfigStorage.update_config_value(:string, "settings", "timezone", tz)
        :ok
    end
  end

  def terminate(_,_) do
    BotState.set_sync_status(:sync_error)
  end

  def handle_call(:current_repo, _, %{repos: [repo_a, _]} = state) do
    {:reply, repo_a, state}
  end

  def handle_call(:other_repo, _, %{repos: [_, repo_b]} = state) do
    {:reply, repo_b, state}
  end

  def handle_call(:flip, _, %{repos: [repo_a, repo_b], needs_hard_sync: true} = state) do
    Logger.warn 3, "Forcing full sync."
    BotState.set_sync_status(:syncing)
    do_sync_all_resources(repo_a)
    do_sync_all_resources(repo_b)
    BotState.set_sync_status(:synced)
    copy_configs(repo_b)
    flip_repos_in_cs()

    {:reply, :ok, %{state | repos: [repo_b, repo_a], needs_hard_sync: false}}
  end

  def handle_call(:flip, _, %{repos: [repo_a, repo_b]} = state) do
    Logger.busy 3, "Syncing"
    BotState.set_sync_status(:syncing)
    ConfigStorage.all(SyncCmd)
    |> Enum.sort(&Timex.before?(&1.inserted_at, &2.inserted_at))
    |> Enum.each(&apply_sync_cmd(repo_a, &1))

    flip_repos_in_cs()
    BotState.set_sync_status(:synced)
    copy_configs(repo_b)
    Logger.success 3, "Sync complete."
    {:reply, repo_b, %{state | repos: [repo_b, repo_a]}}
  end

  def handle_call({:register_sync_cmd, remote_id, kind, body}, _from, state) do
    [_current_repo, other_repo] = state.repos
    case SyncCmd.changeset(struct(SyncCmd, %{remote_id: remote_id, kind: kind, body: body})) |> ConfigStorage.insert do
      {:ok, sync_cmd} ->
        apply_sync_cmd(other_repo, sync_cmd)
        case auto_sync?() do
          false -> BotState.set_sync_status(:sync_now)
          true -> BotState.set_sync_status(:syncing)
        end
        {:reply, :ok, state}
      {:error, reason} ->
        BotState.set_sync_status(:sync_error)
        Logger.error 1, "Failed to apply sync command: #{inspect reason}"
        {:reply, :error, state}
    end
  end

  defp flip_repos_in_cs do
    case ConfigStorage.get_config_value(:string, "settings", "current_repo") do
      "A" ->
        ConfigStorage.update_config_value(:string, "settings", "current_repo", "B")
      "B" ->
        ConfigStorage.update_config_value(:string, "settings", "current_repo", "A")
    end
  end

  defp strip_struct(%{__struct__: _, __meta__: _} = struct) do
    Map.from_struct(struct) |> Map.delete(:__meta__)
  end

  defp strip_struct(already_map), do: already_map

  defp auto_sync? do
    ConfigStorage.get_config_value(:bool, "settings", "auto_sync")
  end

  defp apply_sync_cmd(repo, %SyncCmd{} = sync_cmd) do
    try do
      do_apply_sync_cmd(repo, sync_cmd)
    rescue
      e in Ecto.InvalidChangesetError ->
        BotState.set_sync_status(:sync_error)
        Logger.error 1, "Failed to apply sync_cmd: (#{repo}) #{inspect sync_cmd} (#{e.action})"
        fix_repo(repo, sync_cmd)
    end
  end

  defp do_apply_sync_cmd(repo, %SyncCmd{remote_id: id, kind: kind, body: nil} = sync_cmd) do
    mod = Module.concat(["Farmbot", "Repo", kind])
    # an object was deleted.
    if Code.ensure_loaded?(mod) do
      Logger.busy 3, "Applying sync_cmd (#{mod}: delete) on #{repo}"
      case repo.get(mod, id) do
        nil -> :ok
        existing ->
          repo.delete!(existing)
          :ok
      end
    else
      Logger.warn 3, "Unknown module: #{mod} #{inspect sync_cmd}"
      :ok
    end
  end

  defp do_apply_sync_cmd(repo, %SyncCmd{remote_id: id, kind: kind, body: obj} = sync_cmd) do
    obj = strip_struct(obj)
    mod = Module.concat(["Farmbot", "Repo", kind])
    if Code.ensure_loaded?(mod) do
      Logger.busy 3, "Applying sync_cmd (#{mod}: insert_or_update on #{repo}"

      # We need to check if this object exists in the database.
      case repo.get(mod, id) do
        # If it does not, just return the newly created object.
        nil ->
          mod.changeset(obj, %{})
          |> repo.insert!

        # if there is an existing record, copy the ecto  meta from the old
        # record. This allows `insert_or_update` to work properly.
        existing ->
          mod.changeset(existing, obj)
          |> repo.update!
      end
    else
      Logger.warn 3, "Unknown module: #{mod} #{inspect sync_cmd}"
    end
  end

  defp fix_repo(_repo, %{body: nil}) do
    # The delete already failed. Nothing we can do. This object doesn't exist anymore.
    :ok
  end

  defp fix_repo(repo, %{kind: kind, id: id, body: _body}) do
    # we failed to update with the `body`

    # Fetch a new copy of this object and insert it.
    obj = kind.fetch(id)
    case repo.get(kind, id) do
      # If it does not, just return the newly created object.
      nil -> obj

      # if there is an existing record, copy the ecto  meta from the old
      # record. This allows `insert_or_update` to work properly.
      existing -> %{obj | __meta__: existing.__meta__}
    end
    # Build a changeset
    |> kind.changeset()
    # Apply it.
    |> repo.insert_or_update!()
  end

  defp do_sync_all_resources(repo) do
    with :ok <- sync_resource(repo, Device, "/api/device"),
         :ok <- sync_resource(repo, FarmEvent, "/api/farm_events"),
         :ok <- sync_resource(repo, Peripheral, "/api/peripherals"),
         :ok <- sync_resource(repo, Point, "/api/points"),
         :ok <- sync_resource(repo, Regimen, "/api/regimens"),
         :ok <- sync_resource(repo, Sequence, "/api/sequences"),
         :ok <- sync_resource(repo, Tool, "/api/tools")
    do
      :ok
    end
  end

  defp sync_resource(repo, resource, slug) do
    Logger.debug 3, "syncing: #{resource} (#{slug})"
    as = if resource in @singular_resources do
      struct(resource)
    else
      [struct(resource)]
    end
    with {:ok, %{status_code: 200, body: body}} <- Farmbot.HTTP.get(slug),
         {:ok, obj} <- Poison.decode(body, as: as)
    do
      do_insert_or_update(repo, obj)
    else
      {:error, reason} -> {:error, resource, reason}
      {:ok, %{status_code: code, body: body}} ->
        case Poison.decode(body) do
          {:ok, %{"error" => msg}} -> {:error, resource, "HTTP ERROR: #{code} #{msg}"}
          {:error, _} -> {:error, resource, "HTTP ERROR: #{code}"}
        end
    end
  end

  defp do_insert_or_update(_, []) do
    :ok
  end

  defp do_insert_or_update(repo, [obj | rest]) do
    with {:ok, _} <- do_insert_or_update(repo, obj) do
      do_insert_or_update(repo, rest)
    end
  end

  defp do_insert_or_update(repo, obj) when is_map(obj) do
    res = case repo.get(obj.__struct__, obj.id) do
      nil ->
        obj.__struct__.changeset(obj, %{}) |> repo.insert
      existing ->
        obj.__struct__.changeset(existing, Map.from_struct(obj))
        |> repo.update()
    end

    case res do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, obj.__struct__, reason}
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      @moduledoc "Storage for Farmbot Resources."
      use Ecto.Repo, otp_app: :farmbot, adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]
    end
  end
end

repos = [Farmbot.Repo.A, Farmbot.Repo.B]

for repo <- repos do
  defmodule repo do
    use Farmbot.Repo
  end
end
