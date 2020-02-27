defmodule FarmbotCore.Asset.CriteriaRetrieverTest do
  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotCore.Asset.{
    CriteriaRetriever,
    Point,
    PointGroup,
    Repo
  }

  setup :verify_on_exit!

  @fake_point_group %PointGroup{
    criteria: %{
      "day" => %{"op" => "<", "days_ago" => 4},
      "string_eq" => %{
        "openfarm_slug" => ["five", "nine"],
        "meta.created_by" => ["plant-detection"]
      },
      "number_eq" => %{"radius" => [6, 10, 11]},
      "number_lt" => %{"x" => 7},
      "number_gt" => %{"z" => 8}
    }
  }

  @n 1000
  def rand, do: Enum.random(0..@n) / 1

  def point_group_with_fake_points do
    Repo.delete_all(PointGroup)
    Repo.delete_all(Point)

    whitelist = [
      %Point{id: 1, x: rand(), y: rand(), z: rand()},
      %Point{id: 2, x: rand(), y: rand(), z: rand()},
      %Point{id: 3, x: rand(), y: rand(), z: rand()}
    ]

    exclusion = [
      %Point{created_at: ~U[2222-12-10 02:22:22.222222Z]},
      %Point{openfarm_slug: "not five"},
      %Point{radius: 10.0},
      %Point{x: 10.0},
      %Point{z: 6.0}
    ]

    incusion = [
      # INCLUSION POINTS
      %Point{created_at: ~U[2222-12-04 02:22:22.222222Z]},
      %Point{openfarm_slug: "five"},
      %Point{radius: 6.0},
      %Point{x: 7.0},
      %Point{z: 8.0}
    ]

    points = whitelist ++ exclusion ++ incusion
    Enum.map(points, fn p -> Repo.insert!(p) end)
    pg = %PointGroup{@fake_point_group | point_ids: [1, 2, 3]}
    Repo.insert!(pg)
    pg
  end

  test "query" do
    _results = CriteriaRetriever.run(point_group_with_fake_points())
  end

  @tag :focus
  test "CriteriaRetriever.flatten/1" do
    expect(Timex, :now, 1, fn -> ~U[2222-12-12 02:22:22.222222Z] end)

    expected = [
      {"created_at", "<", ~U[2222-12-08 02:22:22.222222Z]},
      {"openfarm_slug", "IN", ["five", "nine"]},
      {"radius", "IN", [6, 10, 11]},
      {"x", "<", 7},
      {"z", ">", 8}
    ]

    results = CriteriaRetriever.flatten(@fake_point_group)

    assert Enum.count(expected) == Enum.count(results)

    Enum.map(expected, fn query -> assert Enum.member?(results, query) end)
  end
end
