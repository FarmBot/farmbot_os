defmodule Farmbot.Farmware.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Supervisor.init([Farmbot.Farmware.Installer.Repository.SyncTask], strategy: :one_for_one)
  end
end
