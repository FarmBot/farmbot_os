defmodule FarmbotCore.Asset.Repo.Migrations.ForceReinstallFarmware do
  use Ecto.Migration

  alias FarmbotCore.Asset.{
    Repo,
    FirstPartyFarmware,
    FarmwareInstallation
  }

  # this migration is here because v8 was shipped with a configuration error
  # causing farmware to install to the temporary data partition on the 
  # raspberry pi. 
  def change do
    for %{manifest: %{}} = fwi <- Repo.all(FirstPartyFarmware),
        do: Repo.update!(FirstPartyFarmware.changeset(fwi, %{manifest: nil}))

    for %{manifest: %{}} = fwi <- Repo.all(FarmwareInstallation),
        do: Repo.update!(FarmwareInstallation.changeset(fwi, %{manifest: nil}))
  end
end
