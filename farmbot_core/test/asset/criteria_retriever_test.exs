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

  # Use this is a fake "Timex.now()" value when mocking.
  @now ~U[2222-12-10 02:22:22.222222Z]
  @five_days_ago ~U[2222-12-05 01:11:11.111111Z]

  @n 1000
  def rand, do: Enum.random(0..@n) / 1

  def point!(%{id: id} = params) do
    point =
      Map.merge(
        %Point{
          id: id,
          name: "point #{id}",
          meta: %{},
          plant_stage: "planted",
          created_at: @now,
          pointer_type: "Plant",
          radius: 10.0,
          tool_id: nil,
          discarded_at: nil,
          gantry_mounted: false,
          x: 0.0,
          y: 0.0,
          z: 0.0
        },
        params
      )

    Repo.insert!(point)
    point
  end

  def point_group_with_fake_points do
    Repo.delete_all(PointGroup)
    Repo.delete_all(Point)

    whitelist = [
      %Point{id: 1, x: rand(), y: rand(), z: rand()},
      %Point{id: 2, x: rand(), y: rand(), z: rand()},
      %Point{id: 3, x: rand(), y: rand(), z: rand()}
    ]

    exclusion = [
      %Point{created_at: @now},
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

  test "matching_ids_no_meta - Finds point group critera (excluding meta attrs)" do
    expect(Timex, :now, fn -> @now end)
    pg = point_group_with_fake_points()

    perfect_match =
      point!(%{
        id: 999,
        created_at: @five_days_ago,
        openfarm_slug: "five",
        meta: %{"created_by" => "plant-detection"},
        radius: 10.0,
        x: 6.0,
        z: 9.0
      })

    expected = [perfect_match.id]
    results = CriteriaRetriever.matching_ids_no_meta(pg)
    assert Enum.count(expected) == Enum.count(results)
    Enum.map(expected, fn id -> assert Enum.member?(results, id) end)
  end

  test "run/1" do
    expect(Timex, :now, fn -> @now end)
    pg = point_group_with_fake_points()

    # This one is _almost_ a perfect match,
    # but the meta field is a miss.
    point!(%{
      id: 888,
      created_at: @five_days_ago,
      openfarm_slug: "five",
      meta: %{"created_by" => "not-plant-detection"},
      radius: 10.0,
      x: 6.0,
      z: 9.0
    })

    perfect_match = point!(%{
        id: 999,
        created_at: @five_days_ago,
        openfarm_slug: "five",
        meta: %{"created_by" => "plant-detection"},
        radius: 10.0,
        x: 6.0,
        z: 9.0
      })

    expected = [perfect_match.id, 1, 2, 3]
    results = Enum.map(CriteriaRetriever.run(pg), fn p -> p.id end)
    assert Enum.count(expected) == Enum.count(results)
    Enum.map(expected, fn id -> assert Enum.member?(results, id) end)
  end
end
