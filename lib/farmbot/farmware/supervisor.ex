defmodule Farmbot.Farmware.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.Farmware.Installer.Repository.SyncTask

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init([]) do
    Supervisor.init([SyncTask], strategy: :one_for_one)
  end
end
