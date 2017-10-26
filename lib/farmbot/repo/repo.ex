defmodule Farmbot.Repo do
  @moduledoc "Wrapper between two repos."

  use GenServer
  require Logger

  def current_repo do
    GenServer.call(__MODULE__, :current_repo)
  end

  def other_repo do
    GenServer.call(__MODULE__, :other_repo)
  end

  def flip() do
    GenServer.call(__MODULE__, :flip)
  end

  def register_sync_cmd(sync_cmd) do
    GenServer.call(__MODULE__, {:register_sync_cmd, sync_cmd})
  end

  def start_link(repos) do
    GenServer.start_link(__MODULE__, repos, [name: __MODULE__])
  end

  def init([_repo_a, _repo_b] = repos) do
    {:ok, %{repos: repos, sync_cmds: []}}
  end

  def handle_call(:current_repo, _, %{repos: [repo_a, _]} = state) do
    {:reply, repo_a, state}
  end

  def handle_call(:other_repo, _, %{repos: [_, repo_b]} = state) do
    {:reply, repo_b, state}
  end

  def handle_call(:flip, _, %{repos: [repo_a, repo_b]} = state) do
    Enum.reverse(state.sync_cmds) |> Enum.map(fn(sync_cmd) ->
      apply_sync_cmd(repo_a, sync_cmd)
    end)
    {:reply, repo_b, %{state | repos: [repo_b, repo_a]}}
  end

  def handle_call({:register_sync_cmd, sync_cmd}, _from, state) do
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
        Logger.error "Failed to apply sync_cmd: (#{repo}) #{inspect sync_cmd} (#{e.action})"
        fix_repo(repo, sync_cmd)
    end
  end

  defp do_apply_sync_cmd(repo, %{id: id, kind: mod, body: nil} = sync_cmd) do
    # an object was deleted.
    if Code.ensure_loaded?(mod) do
      Logger.warn "Applying sync_cmd: #{inspect sync_cmd} on #{repo}"
      case repo.get(mod, id) do
        nil -> :ok
        existing ->
          repo.delete!(existing)
          :ok
      end
    else
      Logger.warn "Unknown module: #{mod} #{inspect sync_cmd}"
      :ok
    end
  end

  defp do_apply_sync_cmd(repo, %{id: id, kind: mod, body: obj} = sync_cmd) do
    if Code.ensure_loaded?(mod) do
      Logger.warn "Applying sync_cmd: #{inspect sync_cmd} on #{repo}"

      # We need to check if this object exists in the database.
      case repo.get(mod, id) do
        # If it does not, just return the newly created object.
        nil -> obj

        # if there is an existing record, copy the ecto  meta from the old
        # record. This allows `insert_or_update` to work properly.
        existing -> %{obj | __meta__: existing.__meta__}
      end
      # Build a changeset
      |> mod.changeset()
      # Apply it.
      |> repo.insert_or_update!()
    else
      Logger.warn "Unknown module: #{mod} #{inspect sync_cmd}"
    end
  end

  defp fix_repo(repo, %{body: nil}) do
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
