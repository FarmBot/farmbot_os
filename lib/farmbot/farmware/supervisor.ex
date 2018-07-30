defmodule Farmbot.Farmware.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.Farmware.Installer.Repository.SyncTask

  def reindex do
    path = Farmbot.Farmware.Installer.install_root_path()

    if path && File.exists?(path) do
      for fwname <- File.ls!(path) do
        {:ok, fw} = Farmbot.Farmware.lookup(fwname)
        Farmbot.BotState.register_farmware(fw)
      end
    end
  end

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init([]) do
    Supervisor.init(
      [worker(SyncTask, [], restart: :transient)],
      strategy: :one_for_one
    )
  end
end
