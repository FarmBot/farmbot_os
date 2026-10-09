defmodule FarmbotOS.Asset.CurveTest do
  use ExUnit.Case
  alias FarmbotOS.Asset
  alias FarmbotOS.Asset.{Command, Curve, Repo}

  test "casts and renders the API hash payload" do
    params = %{
      "id" => 123,
      "name" => "Water curve",
      "type" => "water",
      "data" => %{"1" => 100, "5" => 500},
      "created_at" => "2026-10-09T00:00:00.000000Z",
      "updated_at" => "2026-10-09T00:00:00.000000Z"
    }

    changeset = Curve.changeset(%Curve{}, params)
    assert changeset.valid?
    curve = Ecto.Changeset.apply_changes(changeset)
    assert Curve.path() == "/api/curves"

    assert Curve.render(curve) == %{
             id: 123,
             name: "Water curve",
             type: "water",
             data: %{"1" => 100, "5" => 500}
           }
  end

  test "sync creates, updates and deletes a local curve" do
    id = :rand.uniform(10_000_000)
    on_exit(fn -> Command.update("Curve", id, nil) end)
    params = %{id: id, name: "Water curve", type: "water", data: %{"1" => 100}}

    assert :ok = Command.update("Curve", id, params)
    curve = Asset.get_curve(id: id)
    assert curve.data == %{"1" => 100}

    assert :ok = Command.update("Curve", id, %{data: %{"1" => 200, "5" => 500}})
    updated = Asset.get_curve(id: id)
    assert updated.local_id == curve.local_id
    assert updated.data == %{"1" => 200, "5" => 500}

    Asset.Private.mark_stale!(updated)
    assert Repo.preload(updated, :local_meta).local_meta.table == "curves"

    assert :ok = Command.update("Curve", id, nil)
    refute Asset.get_curve(id: id)
  end
end
