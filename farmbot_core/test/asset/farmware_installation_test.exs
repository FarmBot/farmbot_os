defmodule FarmbotCore.Asset.FarmwareInstallationTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.FarmwareInstallation

  def fake_install() do
    %FarmwareInstallation{
      id: 23,
      url: "http://www.lycos.com",
      manifest: %{
        package: "xpackage",
        language: "xlanguage",
        author: "xauthor",
        description: "xdescription",
        url: "xurl",
        zip: "xzip",
        executable: "xexecutable",
        args: "xargs",
        config: "xconfig",
        package_version: "xpackage_version",
        farmware_manifest_version: "xfarmware_manifest_version",
        farmware_tools_version_requirement:
          "xfarmware_tools_version_requirement",
        farmbot_os_version_requirement: "xfarmbot_os_version_requirement"
      }
    }
  end

  test "changeset" do
    cs = FarmwareInstallation.changeset(fake_install())
    assert cs.valid?
  end

  test "view" do
    pg = fake_install()

    expected = %{id: 23, url: "http://www.lycos.com"}

    actual = FarmwareInstallation.render(pg)
    assert expected == actual
  end
end
