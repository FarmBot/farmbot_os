defmodule Farmbot.System.UpdatesTest do
  use ExUnit.Case, async: false
  alias Farmbot.System.Updates
  alias Farmbot.System.Updates.{Release, CurrentStuff}
  @old_version Farmbot.Project.version |> Version.parse! |> Map.update(:major, nil, &Kernel.-(&1, 1)) |> to_string()
  @new_version Farmbot.Project.version |> Version.parse! |> Map.update(:major, nil, &Kernel.+(&1, 1)) |> to_string()
  @commit Farmbot.Project.commit
  @version Farmbot.Project.version()
  @os_update_server "http://fake_os_update_server.com"
  @beta_os_update_server "http://beta_os_update_server.com"
  @fake_asset_url "http://fake_release_asset.com"

  describe "CurrentStuff replacement" do
    test "replaces valid things in the current stuff struct" do
      r = CurrentStuff.get(env: :almost_prod)
      assert r.env == :almost_prod
    end

    test "Allows and igrnores arbitry data" do
      r = CurrentStuff.get(some_key: :some_val)
      refute Map.get(r, :some_key)
    end
  end

  @tag :external
  test "checks for updates for prod rpi3 no beta combo" do
    # updating from old to new version should work
    current = CurrentStuff.get(os_update_server_overwrite: nil, beta_opt_in: false, env: :prod, target: :rpi3, version: @old_version)
    assert Updates.check_updates(nil, current)
  end

  @tag :external
  test "checks for updates for prod rpi3 with beta combo" do
    # old version to later beta
    current = CurrentStuff.get(os_update_server_overwrite: nil, env: :prod, target: :rpi3, version: @old_version, beta_opt_in: true)
    assert Updates.check_updates(nil, current)
  end

  test "no token gives error" do
    current = CurrentStuff.get(token: nil)
    assert match?({:error, _}, Updates.check_updates(nil, current))
  end

  test "dev env should not update to prod" do
    current = CurrentStuff.get(env: :dev)
    assert match?({:error, _}, Updates.check_updates(nil, current))
  end


  test "updates of the same version should not return a url" do
    current = CurrentStuff.get(current_stub())
    release = release_stub()
    refute Updates.check_updates(release, current)
  end

  test "Draft releases" do
    current = CurrentStuff.get(current_stub())
    release = %{release_stub() | draft: true}
    refute Updates.check_updates(release, current)
  end

  test "Opting into beta won't downgrade from a prod release to a previous beta" do
    current = CurrentStuff.get(%{current_stub() | beta_opt_in: true, version: @new_version})
    release = release_stub()
    refute Updates.check_updates(release, current)
  end

  test "Normal upgrade path: current is less than latest" do
    current = CurrentStuff.get(%{current_stub() | version: @old_version})
    release = release_stub()
    assert Updates.check_updates(release, current) == @fake_asset_url
  end

  test "versions equal, but commits not equal" do
    current = CurrentStuff.get(%{current_stub() | commit: String.reverse(@commit)})
    release = release_stub()
    assert Updates.check_updates(release, current) == @fake_asset_url
  end

  defp current_stub do
    %{
      token: %Farmbot.Jwt{
        os_update_server: @os_update_server,
        beta_os_update_server: @beta_os_update_server,
      },
      beta_opt_in: false,
      os_update_server_overwrite: nil,
      env: :prod,
      commit: @commit,
      target: :rpi3,
      version: @version
    }
  end

  defp release_stub do
    %Release{
      tag_name: "v#{@version}",
      target_commitish: @commit,
      name: "Stub Release",
      draft: false,
      prerelease: false,
      body: "This is a stub!",
      assets:  [%Release.Asset{name: "farmbot-rpi3-#{@version}.fw", browser_download_url: @fake_asset_url}]
    }
  end

end
