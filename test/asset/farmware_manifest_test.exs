defmodule FarmbotCore.Asset.FarmwareInstallation.ManifestTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.FarmwareInstallation.Manifest

  @expected_keys [
    :args,
    :author,
    :config,
    :description,
    :executable,
    :farmbot_os_version_requirement,
    :farmware_manifest_version,
    :farmware_tools_version_requirement,
    :language,
    :package,
    :package_version,
    :url,
    :zip
  ]

  test "view/1" do
    result = Manifest.view(%Manifest{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
