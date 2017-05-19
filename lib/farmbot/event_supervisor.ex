defmodule Farmbot.EventSupervisor do
  @moduledoc """
    Behavior for event supervisors.
  """
  alias Supervisor.Spec
  alias Farmbot.Sync.Database
  alias Database.Syncable.{Sequence, Regimen}
  alias Farmbot.Context

  @callback add_child(Context.t, Regimen.t | Sequence.t, DateTime.t)
    :: Spec.spec

  @callback remove_child(Context.t, Regimen.t | Sequence.t)
    :: :ok | {:error, error} when error: :not_found | :simple_one_for_one
end
