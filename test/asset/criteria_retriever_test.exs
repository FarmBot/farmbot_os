defmodule FarmbotOS.Asset.CriteriaRetrieverTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Asset.{
    CriteriaRetriever,
    Point,
    PointGroup,
    Repo
  }

  setup :verify_on_exit!

  @fake_point_group %PointGroup{
    criteria: %{
      "day" => %{"op" => ">", "days_ago" => 4},
      "string_eq" => %{
        "openfarm_slug" => ["five", "nine"],
        "meta.created_by" => ["plant-detection"]
      },
      "number_eq" => %{"radius" => [6, 10, 11]},
      "number_lt" => %{"x" => 7},
      "number_gt" => %{"z" => 8}
    }
  }

  @simple_point_group %PointGroup{
    point_ids: [],
    sort_type: "xy_ascending",
    criteria: %{
      "day" => %{
        "op" => "<",
        "days_ago" => 0
      },
      "string_eq" => %{
        "pointer_type" => ["Plant"]
      },
      "number_eq" => %{},
      "number_lt" => %{},
      "number_gt" => %{}
    }
  }

  # Use this is a fake "Timex.now()" value when mocking.
  @now ~U[2222-12-10 02:22:22.222222Z]
  @five_days_ago ~U[2222-12-05 01:11:11.111111Z]

  @n 1000
  def rand, do: Enum.random(0..@n) / 1

  def point_group_with_fake_points do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

    ok = [
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

    inclusion = [
      # INCLUSION POINTS
      %Point{created_at: ~U[2222-12-04 02:22:22.222222Z]},
      %Point{openfarm_slug: "five"},
      %Point{radius: 6.0},
      %Point{x: 7.0},
      %Point{z: 8.0}
    ]

    points = ok ++ exclusion ++ inclusion
    Enum.map(points, fn p -> Repo.insert!(p) end)
    pg = %PointGroup{@fake_point_group | point_ids: [1, 2, 3]}
    Repo.insert!(pg)
    pg
  end

  test "direct match on `pointer_type` via `string_eq`" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

    Helpers.create_point(%{id: 1, pointer_type: "Plant"})
    Helpers.create_point(%{id: 2, pointer_type: "Weed"})
    Helpers.create_point(%{id: 3, pointer_type: "ToolSlot"})
    Helpers.create_point(%{id: 4, pointer_type: "GenericPointer"})

    result = CriteriaRetriever.run(@simple_point_group)
    assert Enum.count(result) == 1
  end

  test "run/1" do
    expect(Timex, :now, fn -> @now end)
    pg = point_group_with_fake_points()

    Helpers.create_point(%{
      id: 888,
      created_at: @five_days_ago,
      planted_at: @five_days_ago,
      openfarm_slug: "five",
      meta: %{"created_by" => "not-plant-detection"},
      radius: 10.0,
      x: 6.0,
      z: 9.0
    })

    perfect_match =
      Helpers.create_point(%{
        id: 999,
        created_at: @five_days_ago,
        planted_at: @five_days_ago,
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

  @tag :capture_log
  test "point group that does not define criteria" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

    ok = [88457, 88455]

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:39.176321Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88455,
      meta: %{},
      name: "Spinach",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 400.0,
      y: 100.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:39.413318Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88456,
      meta: %{},
      name: "Spinach",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 400.0,
      y: 300.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:39.610901Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88457,
      meta: %{},
      name: "Spinach",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 600.0,
      y: 100.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:39.824048Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88458,
      meta: %{},
      name: "Spinach",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 600.0,
      y: 300.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:40.012075Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88459,
      meta: %{},
      name: "Spinach",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 800.0,
      y: 300.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:40.202385Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88460,
      meta: %{},
      name: "Spinach",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 800.0,
      y: 100.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:40.402777Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88461,
      meta: %{},
      name: "Broccoli",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 600.0,
      y: 700.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:40.776337Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88462,
      meta: %{},
      name: "Beets",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 800.0,
      y: 1.1e3,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:40.960424Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88463,
      meta: %{},
      name: "Beets",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 600.0,
      y: 1.1e3,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:41.171967Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88464,
      meta: %{},
      name: "Beets",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 400.0,
      y: 1.1e3,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-01-09 19:09:41.393021Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88465,
      meta: %{},
      name: "Beets",
      openfarm_slug: nil,
      plant_stage: "planned",
      planted_at: nil,
      pointer_type: "Plant",
      radius: 25.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 200.0,
      y: 1.1e3,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-02-21 01:41:07.714000Z],
      discarded_at: nil,
      gantry_mounted: true,
      id: 88798,
      meta: %{},
      name: "Tool Slot",
      openfarm_slug: nil,
      plant_stage: nil,
      planted_at: nil,
      pointer_type: "ToolSlot",
      radius: nil,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 0.0,
      y: 0.0,
      z: -20.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-02-21 18:30:56.301000Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88805,
      meta: %{},
      name: "Slot",
      openfarm_slug: nil,
      plant_stage: nil,
      planted_at: nil,
      pointer_type: "ToolSlot",
      radius: nil,
      tool_id: 12143,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 200.0,
      y: 200.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-02-21 18:47:45.170000Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88806,
      meta: %{},
      name: "Slot",
      openfarm_slug: nil,
      plant_stage: nil,
      planted_at: nil,
      pointer_type: "ToolSlot",
      radius: nil,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 0.0,
      y: 0.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-02-21 20:01:59.960000Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88828,
      meta: %{
        "color" => "green",
        "created_by" => "farm-designer",
        "type" => "point"
      },
      name: "Created Point",
      openfarm_slug: nil,
      plant_stage: nil,
      planted_at: nil,
      pointer_type: "GenericPointer",
      radius: 15.0,
      tool_id: nil,
      updated_at: ~U[1970-11-07 16:52:31.618000Z],
      x: 1.0,
      y: 1.0,
      z: 0.0
    })

    Helpers.create_point(%{
      created_at: ~U[2020-02-29 21:08:40.934000Z],
      discarded_at: nil,
      gantry_mounted: false,
      id: 88887,
      meta: %{
        "color" => "red",
        "created_by" => "farm-designer",
        "type" => "weed"
      },
      name: "Created Weed",
      openfarm_slug: nil,
      plant_stage: nil,
      planted_at: nil,
      pointer_type: "GenericPointer",
      radius: 15.0,
      tool_id: nil,
      updated_at: ~U[2020-02-29 21:08:40.934000Z],
      x: 100.0,
      y: 100.0,
      z: 0.0
    })

    pg = %PointGroup{
      created_at: ~U[2020-02-29 21:14:33.337000Z],
      criteria: %{
        "day" => %{"days_ago" => 0, "op" => "<"},
        "number_eq" => %{},
        "number_gt" => %{},
        "number_lt" => %{},
        "string_eq" => %{}
      },
      id: 201,
      name: "Test (Broke?)",
      point_ids: ok,
      sort_type: "xy_ascending",
      updated_at: ~U[2020-03-02 21:55:26.973000Z]
    }

    Repo.insert!(pg)
    results = Enum.map(CriteriaRetriever.run(pg), fn p -> p.id end)
    assert Enum.count(ok) == Enum.count(results)
    Enum.map(ok, fn id -> assert Enum.member?(results, id) end)
  end

  test "edge case: Filter by crop type" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

    ok =
      Helpers.create_point(%{
        id: 1,
        pointer_type: "Plant",
        openfarm_slug: "spinach"
      })

    Helpers.create_point(%{
      id: 2,
      pointer_type: "Plant",
      openfarm_slug: "beetroot"
    })

    Helpers.create_point(%{
      id: 3,
      pointer_type: "Weed",
      openfarm_slug: "thistle"
    })

    Helpers.create_point(%{
      id: 4,
      pointer_type: "Weed",
      openfarm_slug: "spinach"
    })

    pg = %PointGroup{
      :id => 241,
      :point_ids => [],
      :criteria => %{
        "day" => %{
          "op" => "<",
          "days_ago" => 0
        },
        "string_eq" => %{
          "pointer_type" => ["Plant"],
          "openfarm_slug" => ["spinach"]
        },
        "number_eq" => %{},
        "number_lt" => %{},
        "number_gt" => %{}
      }
    }

    ids = CriteriaRetriever.run(pg) |> Enum.map(fn p -> p.id end)
    assert Enum.member?(ids, ok.id)
    assert Enum.count(ids) == 1
  end

  test "edge case: Retrieves by `day` criteria only" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()
    days_ago4 = Timex.shift(@now, days: -4)
    days_ago2 = Timex.shift(@now, days: -2)
    expect(Timex, :now, fn -> @now end)

    Helpers.create_point(%{
      id: 1,
      pointer_type: "Plant",
      created_at: days_ago4
    })

    p2 =
      Helpers.create_point(%{
        id: 2,
        pointer_type: "Plant",
        created_at: days_ago2
      })

    p3 =
      Helpers.create_point(%{
        id: 3,
        pointer_type: "Plant",
        created_at: days_ago4,
        planted_at: days_ago2
      })

    Helpers.create_point(%{
      id: 4,
      pointer_type: "Plant",
      created_at: days_ago2,
      planted_at: days_ago4
    })

    pg1 = %PointGroup{
      id: 212,
      created_at: Timex.shift(@now, hours: -1),
      updated_at: Timex.shift(@now, hours: -1),
      name: "Less than 2 days ago",
      point_ids: [],
      sort_type: "yx_descending",
      criteria: %{
        day: %{"op" => "<", "days_ago" => 3},
        string_eq: %{},
        number_eq: %{},
        number_lt: %{},
        number_gt: %{}
      }
    }

    ids = CriteriaRetriever.run(pg1) |> Enum.map(fn p -> p.id end)
    assert Enum.count(ids) == 1
    assert Enum.member?(ids, p3.id)
  end

  test "edge case: Filter by slot direction" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

    ok =
      Helpers.create_point(%{
        id: 1,
        pointer_type: "ToolSlot",
        pullout_direction: 3
      })

    Helpers.create_point(%{id: 2, pointer_type: "Weed", pullout_direction: 3})

    Helpers.create_point(%{
      id: 3,
      pointer_type: "ToolSlot",
      pullout_direction: 4
    })

    Helpers.create_point(%{
      id: 4,
      pointer_type: "GenericPointer",
      pullout_direction: 2
    })

    pg = %PointGroup{
      :id => 242,
      :name => "Filter by slot direction",
      :point_ids => [],
      :sort_type => "xy_ascending",
      :criteria => %{
        "day" => %{
          "op" => "<",
          "days_ago" => 0
        },
        "string_eq" => %{
          "pointer_type" => ["ToolSlot"]
        },
        "number_eq" => %{
          "pullout_direction" => [3]
        },
        "number_lt" => %{},
        "number_gt" => %{}
      }
    }

    ids = CriteriaRetriever.run(pg) |> Enum.map(fn p -> p.id end)
    assert Enum.member?(ids, ok.id)
    assert Enum.count(ids) == 1
  end
end
