defmodule Farmbot.Farmware.Installer.Repository.Farmbot do
  @moduledoc false
  @behaviour Farmbot.Farmware.Installer.Repository
  def url, do: "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/a9f391fd309f61de5da4d181418032aab08e31a6/manifest.json"
end
