defmodule Farmbot.System.UpdatesTest do
  use ExUnit.Case, async: false
  alias Farmbot.System.Updates
  alias Farmbot.System.Updates.{Release, CurrentStuff}
  @old_version Farmbot.Project.version |> Version.parse! |> Map.update(:major, nil, &Kernel.-(&1, 1)) |> to_string()

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

  test "checks for updates for prod rpi3 no beta combo" do
    # updating from old to new version should work
    current = CurrentStuff.get(os_update_server_overwrite: nil, beta_opt_in: false, env: :prod, target: :rpi3, version: @old_version)
    assert Updates.check_updates(nil, current)
  end

  test "checks for updates for prod rpi3 with beta combo" do
    # old version to later beta
    current = CurrentStuff.get(os_update_server_overwrite: nil, env: :prod, target: :rpi3, version: @old_version, beta_opt_in: true)
    assert Updates.check_updates(nil, current)
  end

end
