defmodule FarmbotCore.Asset.CriteriaRetrieverTest do
  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotCore.Asset.{
    CriteriaRetriever,
    PointGroup
  }

  setup :verify_on_exit!

  @fake_point %PointGroup{
    point_ids: [1, 2, 3],
    criteria: %{
      "day" => %{"op" => "<", "days_ago" => 4},
      "string_eq" => %{
        "openfarm_slug" => ["five"],
        "meta.created_by" => ["plant-detection"]
      },
      "number_eq" => %{"radius" => [6]},
      "number_lt" => %{"x" => 7},
      "number_gt" => %{"z" => 8}
    }
  }

  test "CriteriaRetriever.flatten/1" do
    expect(Timex, :now, 1, fn -> ~U[2222-12-12 02:22:22.222222Z] end)

    expected = [
      ["created_at < ?", ~U[2222-12-08 02:22:22.222222Z]],
      ["openfarm_slug IN ?", ["five"]],
      ["radius IN ?", [6]],
      ["x < ?", 7],
      ["z > ?", 8]
    ]

    {_pg, results} = CriteriaRetriever.flatten(fake_point)

    assert Enum.count(expected) == Enum.count(results)

    Enum.map(expected, fn query -> assert Enum.member?(results, query) end)
  end
end
