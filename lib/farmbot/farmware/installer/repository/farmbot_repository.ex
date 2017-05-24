defmodule Farmbot.Farmware.Installer.Repository.Farmbot do
  @behaviour Farmbot.Farmware.Installer.Repository
  def url, do: "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json"
end
