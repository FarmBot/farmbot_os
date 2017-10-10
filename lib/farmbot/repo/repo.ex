defmodule Farmbot.Repo do
  @moduledoc "Wrapper between two repos."

  use GenServer

  def repo(repo_worker) do
    GenServer.call(repo_worker, :repo)
  end

  def flip(repo_worker) do
    GenServer.call(repo_worker, :flip)
  end

  def start_link(repos, opts \\ []) do
    GenServer.start_link(__MODULE__, repos, opts)
  end

  def init([_repo_a, _repo_b] = repos) do
    {:ok, repos}
  end

  def handle_call(:repo, _, [repo, _] = repos) do
    {:reply, repo, repos}
  end

  def handle_call(:flip, _, [repo_a, repo_b]) do
    {:reply, repo_b, [repo_b, repo_a]}
  end

  @doc false
  defmacro __using__(_) do
    quote do


      @moduledoc "Storage for Farmbot Resources."
      use Ecto.Repo, otp_app: :farmbot, adapter: Sqlite.Ecto2

      alias Farmbot.Repo.{
        FarmEvent, GenericPointer, Peripheral,
        Point, Regimen, Sequence, ToolSlot, Tool
      }

      @default_syncables [FarmEvent, GenericPointer, Peripheral,
                          Point, Regimen, Sequence, ToolSlot, Tool]

      @doc "A list of all the resources."
      def syncables, do: Application.get_env(:farmbot, :repo)[:farmbot_syncables] || @default_syncables

      @doc "Sync all the modules that export a `sync/1` function."
      def sync!(http \\ Farmbot.HTTP) do
        for syncable <- syncables() do
          if Code.ensure_loaded?(syncable) and function_exported?(syncable, :sync!, 2) do
            spawn fn() ->
              syncable.sync!(__MODULE__, http)
            end
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
