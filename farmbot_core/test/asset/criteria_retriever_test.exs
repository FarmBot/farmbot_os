defmodule FarmbotCore.Asset.CriteriaRetrieverTest do
  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotCore.Asset.{
    CriteriaRetriever,
    Repo,
    PointGroup
  }

  setup :verify_on_exit!

  test "CriteriaRetriever.flatten/1" do
    expect(Timex, :now, 1, fn -> ~U[2020-02-21 12:34:56.789012Z] end)

    expected = [
      {:and, ["created_at < ?", ~U[2020-02-18 12:34:56.789012Z]]},
      {:and, ["openfarm_slug = ?", "five"]},
      {:and, ["radius = ?", 6]},
      {:and, ["x < ?", 7]},
      {:and, ["z > ?", 8]}
    ]

    results =
      CriteriaRetriever.flatten(%PointGroup{
        point_ids: [1, 2, 3],
        criteria: %{
          "day" => %{"op" => "<", "days" => 4},
          "string_eq" => %{"openfarm_slug" => "five"},
          "number_eq" => %{"radius" => 6},
          "number_lt" => %{"x" => 7},
          "number_gt" => %{"z" => 8}
        }
      })

    assert Enum.count(expected) == Enum.count(results)

    Enum.map(expected, fn query ->
      assert Enum.member?(results, query)
    end)
  end
end
