defmodule FarmbotCore.Asset.PrivateTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.{Private, Repo, Private.Alert}

  import Farmbot.TestSupport.AssetFixtures,
    only: [
      alert: 0
    ]

  describe "alerts" do
    test "create_or_update_alert!() returns :ok" do
      result = alert()
      assert result.priority == 100
      assert result.problem_tag == "farmbot_os.firmware.missing"
      assert result.created_at

      result2 =
        Private.create_or_update_alert!(%{
          problem_tag: result.problem_tag,
          priority: 50
        })

      assert result.local_id == result2.local_id
      assert result2.priority == 50
    end

    test "clear_alert() clears out alerts by problem_tag" do
      alert1 = alert()
      assert Repo.get_by(Alert, problem_tag: alert1.problem_tag)
      Private.clear_alert!(alert1.problem_tag)
      assert Repo.get_by(Alert, problem_tag: alert1.problem_tag).status == "resolved"
    end
  end
end
