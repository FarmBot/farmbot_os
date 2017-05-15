defmodule Farmbot.EventSupervisor do
  @moduledoc """
    Behavior for event supervisors.
  """
  alias Supervisor.Spec
  alias Farmbot.Sync.Database
  alias Database.Syncable.Regimen
  alias Database.Syncable.Sequence
  @callback add_child(Regimen.t | Sequence.t, DateTime.t) :: Spec.spec
  @callback remove_child(Regimen.t | Sequence.t)
    :: :ok | {:error, error} when error: :not_found | :simple_one_for_one
end
