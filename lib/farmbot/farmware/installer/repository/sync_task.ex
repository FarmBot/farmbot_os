defmodule Farmbot.Farmware.Installer.Repository.SyncTask do
  @moduledoc "Init module for installing first party farmware repo. Requires internet."
  use Task, restart: :transient
  require Logger
  alias Farmbot.System.ConfigStorage
  alias Farmbot.Farmware.Installer
  alias Farmbot.Farmware.Installer.Repository

  @fpf_url Application.get_env(:farmbot, :farmware)[:first_part_farmware_manifest_url] || raise "First party farmware url needs to be configured"

  @doc false
  def start_link(_) do
    Task.start_link(__MODULE__, :sync_all, [])
  end

  def sync_all do
    Logger.debug "Syncing all repos. This may take a while."
    import Ecto.Query
    unless Farmbot.System.ConfigStorage.one(from r in Repository, where: r.url == @fpf_url) do
      Installer.add_repo(@fpf_url)
    end

    repos = ConfigStorage.all(Repository)
    for repo <- repos do
      Installer.sync_repo(repo)
    end
  end
end
