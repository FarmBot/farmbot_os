defmodule Farmbot.Repo do
  @moduledoc "Wrapper between two repos."

  use GenServer

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
      mod = Module.concat(["Farmbot", "Repo", sync_cmd["kind"]])
      mod.changeset(struct(mod), sync_cmd["body"]) |> repo_a.insert_or_update!()
    end)
    {:reply, repo_b, %{state | repos: [repo_b, repo_a]}}
  end

  def handle_call({:register_sync_cmd, sync_cmd}, _from, state) do
    {:reply, :ok, %{state | sync_cmds: [sync_cmd | state.sync_cmds]}}
  end

  @doc false
  defmacro __using__(_) do
    quote do
      @moduledoc "Storage for Farmbot Resources."
      use Ecto.Repo, otp_app: :farmbot, adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]

      alias Farmbot.Repo.{
              FarmEvent,
              GenericPointer,
              Peripheral,
              Point,
              Regimen,
              Sequence,
              ToolSlot,
              Tool
            }

      @default_syncables [
        FarmEvent,
        GenericPointer,
        Peripheral,
        Point,
        Regimen,
        Sequence,
        ToolSlot,
        Tool
      ]

      @doc "A list of all the resources."
      def syncables,
        do: Application.get_env(:farmbot, :repo)[:farmbot_syncables] || @default_syncables

      @doc "Sync all the modules that export a `sync/1` function."
      def sync!(http \\ Farmbot.HTTP) do
        for syncable <- syncables() do
          if Code.ensure_loaded?(syncable) and function_exported?(syncable, :sync!, 2) do
            spawn(fn ->
              syncable.sync!(__MODULE__, http)
            end)

            :ok
          end

          :ok
        end

        :ok
      end
    end
  end
end

repos = [Farmbot.Repo.A, Farmbot.Repo.B]

for repo <- repos do
  defmodule repo do
    use Farmbot.Repo
  end
end
