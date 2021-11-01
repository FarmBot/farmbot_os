defimpl FarmbotOS.AssetWorker, for: FarmbotOS.Asset.FarmEvent do
  require Logger

  alias FarmbotOS.Asset.FarmEvent

  alias FarmbotOS.FarmEventWorker.{
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
