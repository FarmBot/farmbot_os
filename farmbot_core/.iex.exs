alias FarmbotCore.{Asset, Asset.Repo}

alias FarmbotCore.Asset.{
  Device,
  FarmwareEnv,
  FarmwareInstallation,
  FarmEvent,
  FbosConfig,
  FirmwareConfig,
  PinBinding,
  Regimen,
  RegimenInstance,
  Sequence
}

alias Farmbot.TestSupport.AssetFixtures

defmodule Farmbot.Helpers do
  def new_farmware(url) do
    %FarmwareInstallation{
      url: url,
      id: :rand.uniform(1000)
    }
    |> Repo.insert!()
  end
end
