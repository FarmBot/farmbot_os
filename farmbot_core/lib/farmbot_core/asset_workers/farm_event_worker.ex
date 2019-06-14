defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FarmEvent do
  require Logger

  alias FarmbotCore.Asset.FarmEvent
  alias FarmbotCore.FarmEventWorker.{
    RegimenEvent,
    SequenceEvent
  }

  def preload(%FarmEvent{}), do: [:executions]

  def tracks_changes?(%FarmEvent{}), do: false

  def start_link(%{executable_type: "Regimen"} = farm_event, args) do
    GenServer.start_link(RegimenEvent, [farm_event, args])
  end

  def start_link(%{executable_type: "Sequence"} = farm_event, args) do
    GenServer.start_link(SequenceEvent, [farm_event, args])
  end
end
