defmodule FarmbotCore.Asset.PointGroupTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.PointGroup

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
      sort_type: "random"
    }

    actual = PointGroup.render(pg)
    assert expected == actual
  end
end
