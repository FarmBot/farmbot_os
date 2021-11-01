defmodule FarmbotOS.Asset.PointGroupTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.PointGroup

  def fake_pg() do
    %PointGroup{
      id: 23,
      name: "wow",
      point_ids: [1, 2],
      sort_type: "random"
    }
  end

  test "changeset" do
    cs = PointGroup.changeset(fake_pg())
    assert cs.valid?
  end

  test "view" do
    pg = fake_pg()

    expected = %{
      id: 23,
      name: "wow",
      point_ids: [1, 2],
      sort_type: "random",
      criteria: %{
        "day" => %{"days_ago" => 0, "op" => ">"},
        "number_eq" => %{},
        "number_gt" => %{},
        "number_lt" => %{},
        "string_eq" => %{}
      }
    }

    actual = PointGroup.render(pg)
    assert expected == actual
  end
end
