defmodule Farmbot.Farmware.Installer.Repository.SyncTask do
  @moduledoc "Init module for installing first party farmware repo. Requires internet."
  use Task, restart: :transient
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  alias Farmbot.Farmware.Installer
  alias Farmbot.Farmware.Installer.Repository

  @doc false
  def start_link(_) do
    Task.start_link(__MODULE__, :sync_all, [])
  end

  def sync_all do
    Logger.busy 2, "Syncing all repos. This may take a while."
    import Ecto.Query

    # first party farmware url could be nil. This would mean it is disabled.
    fpf_url = ConfigStorage.get_config_value(:string, "settings", "first_party_farmware_url")
    # if fpf_url isn't nil, check if its been enabled, if not enable it.
    if fpf_url do
      unless Farmbot.System.ConfigStorage.one(from r in Repository, where: r.url == ^fpf_url) do
        Installer.add_repo(fpf_url)
      end
    else
      Logger.warn 2, "First party farmware is disabled."
    end

    repos = ConfigStorage.all(Repository)
    for repo <- repos do
      Installer.sync_repo(repo)
    end
  end
end
