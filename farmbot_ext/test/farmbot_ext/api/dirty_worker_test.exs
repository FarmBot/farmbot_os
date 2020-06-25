defmodule FarmbotExt.API.DirtyWorkerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotCore.Asset.Point
  alias FarmbotCore.Asset.Private
  alias FarmbotExt.API.DirtyWorker
  alias FarmbotCore.Asset.Private.LocalMeta
  alias FarmbotCore.Asset.Repo

  setup :verify_on_exit!

  test "child spec" do
    spec = DirtyWorker.child_spec(Point)
    assert spec[:id] == {DirtyWorker, Point}
    assert spec[:start] == {DirtyWorker, :start_link, [[module: Point, timeout: 500]]}
    assert spec[:type] == :worker
    assert spec[:restart] == :permanent
    assert spec[:shutdown] == 500
  end

  test "maybe_resync runs when there is stale data" do
    Helpers.delete_all_points()
    p = Helpers.create_point(%{id: 1, pointer_type: "Plant"})
    Private.mark_stale!(p)
    assert Private.any_stale?()

    expect(FarmbotCeleryScript.SysCalls, :sync, 1, fn ->
      Private.mark_clean!(p)
    end)

    DirtyWorker.maybe_resync(0)
  end

  test "maybe_resync does not run when there is *NOT* stale data" do
    Helpers.delete_all_points()
    Repo.delete_all(LocalMeta)

    stub(FarmbotCeleryScript.SysCalls, :sync, fn ->
      flunk("Never should call sync")
    end)

    refute(Private.any_stale?())
    refute(DirtyWorker.maybe_resync(0))
  end
end
