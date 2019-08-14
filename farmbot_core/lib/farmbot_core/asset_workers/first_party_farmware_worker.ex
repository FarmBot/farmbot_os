defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FirstPartyFarmware do
  @moduledoc false
  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmwareInstallation
  require FarmbotCore.Logger

  def preload(fwi) do
    fwi = %{fwi | __struct__: FarmbotCore.Asset.FarmwareInstallation}
    FarmwareInstallation.preload(fwi)
  end

  def tracks_changes?(fwi) do
    fwi = %{fwi | __struct__: FarmbotCore.Asset.FarmwareInstallation}
    FarmwareInstallation.tracks_changes?(fwi)
  end

  def start_link(fwi, args) do
    fwi = %{fwi | __struct__: FarmbotCore.Asset.FarmwareInstallation}
    FarmwareInstallation.start_link(fwi, args)
  end
end