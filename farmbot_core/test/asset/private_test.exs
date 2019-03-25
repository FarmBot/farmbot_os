defmodule FarmbotCore.Asset.PrivateTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.{Private, Repo, Private.Enigma}

  import Farmbot.TestSupport.AssetFixtures,
    only: [
      enigma: 0
    ]

  describe "enigmas" do
    test "create_or_update_enigma!() returns :ok" do
      result = enigma()
      assert result.priority == 100
      assert result.problem_tag == "firmware.missing"
      assert result.created_at

      result2 =
        Private.create_or_update_enigma!(%{
          problem_tag: result.problem_tag,
          priority: 50
        })

      assert result.local_id == result2.local_id
      assert result2.priority == 50
    end

    test "clear_enigma() clears out enigmas by problem_tag" do
      enigma1 = enigma()
      assert Repo.get_by(Enigma, problem_tag: enigma1.problem_tag)
      Private.clear_enigma!(enigma1.problem_tag)
      assert Repo.get_by(Enigma, problem_tag: enigma1.problem_tag).status == "resolved"
    end
  end
end
