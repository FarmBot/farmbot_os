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
  def register_sync_cmd(sync_cmd) do
    GenServer.call(__MODULE__, {:register_sync_cmd, sync_cmd}, :infinity)
  end

  @doc false
  def start_link(repos) do
    GenServer.start_link(__MODULE__, repos, [name: __MODULE__])
  end

  def init([repo_a, repo_b]) do
    if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "first_sync") do
      do_sync_all_resources(repo_a)
      do_sync_all_resources(repo_b)
      Farmbot.System.ConfigStorage.update_config_value(:bool, "settings", "first_sync", false)
    end

    repos = case Farmbot.System.ConfigStorage.get_config_value(:string, "settings", "current_repo") do
      "A" -> [repo_a, repo_b]
      "B" -> [repo_b, repo_a]
    end
    # Copy configs
    [current, _] = repos
    copy_configs(current)
    {:ok, %{repos: repos, sync_cmds: []}}
  end

  defp copy_configs(repo) do
    case repo.one(Farmbot.Repo.Device) do
      nil -> :ok
      %{timezone: tz} ->
        Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "timezone", tz)
        :ok
    end
  end

  def terminate(_,_) do
    Farmbot.BotState.set_sync_status(:sync_error)
  end

  def handle_call(:current_repo, _, %{repos: [repo_a, _]} = state) do
    {:reply, repo_a, state}
  end

  def handle_call(:other_repo, _, %{repos: [_, repo_b]} = state) do
    {:reply, repo_b, state}
  end

  def handle_call(:flip, _, %{repos: [repo_a, repo_b]} = state) do
    Farmbot.BotState.set_sync_status(:syncing)
    Enum.reverse(state.sync_cmds) |> Enum.map(fn(sync_cmd) ->
      apply_sync_cmd(repo_a, sync_cmd)
    end)

    case Farmbot.System.ConfigStorage.get_config_value(:string, "settings", "current_repo") do
      "A" ->
        Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "current_repo", "B")
      "B" ->
        Farmbot.System.ConfigStorage.update_config_value(:string, "settings", "current_repo", "A")
    end
    Farmbot.BotState.set_sync_status(:synced)
    copy_configs(repo_b)
    {:reply, repo_b, %{state | repos: [repo_b, repo_a]}}
  end

  def handle_call({:register_sync_cmd, sync_cmd}, _from, state) do
    Farmbot.BotState.set_sync_status(:sync_now)
    [_current_repo, other_repo] = state.repos
    apply_sync_cmd(other_repo, sync_cmd)
    sync_cmds = if sync_cmd in state.sync_cmds do
      state.sync_cmds
    else
      [sync_cmd | state.sync_cmds]
    end
    {:reply, :ok, %{state | sync_cmds: sync_cmds}}
  end

  defp apply_sync_cmd(repo, sync_cmd) do
    try do
      do_apply_sync_cmd(repo, sync_cmd)
    rescue
      e in Ecto.InvalidChangesetError ->
        Farmbot.BotState.set_sync_status(:sync_error)
        Logger.error 1, "Failed to apply sync_cmd: (#{repo}) #{inspect sync_cmd} (#{e.action})"
        fix_repo(repo, sync_cmd)
    end
  end

  defp do_apply_sync_cmd(repo, %{id: id, kind: mod, body: nil} = sync_cmd) do
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

  defp do_apply_sync_cmd(repo, %{id: id, kind: mod, body: obj} = sync_cmd) do
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
          mod.changeset(existing, Map.from_struct(obj))
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
