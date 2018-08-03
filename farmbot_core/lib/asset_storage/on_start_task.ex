defmodule Farmbot.Asset.OnStartTask do
  alias Farmbot.Asset.Repo
  alias Repo.Snapshot

require Logger

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :dispatch, opts},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  def dispatch do
    old = %Snapshot{}
    new = Repo.snapshot()
    diff = Snapshot.diff(old, new)
    IO.inspect diff, label: "Initial asset dispatch"
    Logger.error "here!!"
    Farmbot.Asset.dispatch_sync(diff)
    :ignore
  end
end
