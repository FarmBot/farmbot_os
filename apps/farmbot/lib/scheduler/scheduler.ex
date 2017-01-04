alias Farmbot.Sync.Database.Regimen
alias Farmbot.Scheduler.RegimenRunner, as: RR
defmodule Farmbot.Scheduler do
  @moduledoc """
    Manages regimens (and one day FarmEvents)
  """
  use Supervisor
  require Logger

  # public api

  @doc """
    Starts a Regimen.
  """
  # reg = %Regimen{name: "AYEE", id: 1, color: "purple", device_id: 1}
  @spec start_regimen(Regimen.t) :: {:ok, pid} | {:error, atom}
  def start_regimen(%Regimen{} = reg) do
    Supervisor.start_child(__MODULE__, worker(RR, [reg], restart: :permanent))
  end

  def init([]) do
    #TODO load the old config of all the runnign things
    children = []
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
end
