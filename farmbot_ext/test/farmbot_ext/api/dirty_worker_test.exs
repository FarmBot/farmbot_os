defmodule FarmbotExt.API.DirtyWorkerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotExt.API.DirtyWorker
  alias FarmbotCore.Asset.Point

  setup :verify_on_exit!

  test "child spec" do
    spec = DirtyWorker.child_spec(Point)
    assert spec[:id] == {DirtyWorker, Point}
    assert spec[:start] == {DirtyWorker, :start_link, [[module: Point, timeout: 500]]}
    assert spec[:type] == :worker
    assert spec[:restart] == :permanent
    assert spec[:shutdown] == 500
  end
end
