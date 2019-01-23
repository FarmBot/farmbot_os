alias Farmbot.{Asset, Asset.Repo}

alias Farmbot.Asset.{
  Device,
  FarmwareEnv,
  FarmwareInstallation,
  FarmEvent,
  FbosConfig,
  FirmwareConfig,
  PinBinding,
  Regimen,
  PersistentRegimen,
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
