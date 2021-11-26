defmodule FarmbotOS.DirtyWorkerTest do
  require Helpers

  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotOS.Asset.{
    FbosConfig,
    Point,
    Private,
    Private.LocalMeta,
    Repo
  }

  alias FarmbotOS.DirtyWorker.Supervisor

  alias FarmbotOS.DirtyWorker

  setup :verify_on_exit!

  test "supervisor" do
    assert [] == Supervisor.children()
    {:ok, _pid} = Supervisor.start_link([], [])
  end

  test "child spec" do
    spec = DirtyWorker.child_spec(Point)
    assert spec[:id] == {DirtyWorker, Point}

    assert spec[:start] ==
             {DirtyWorker, :start_link, [[module: Point, timeout: 1000]]}

    assert spec[:type] == :worker
    assert spec[:restart] == :permanent
    assert spec[:shutdown] == 500
  end

  test "maybe_resync runs when there is stale data" do
    Helpers.delete_all_points()
    p = Helpers.create_point(%{id: 1, pointer_type: "Plant"})
    Private.mark_stale!(p)
    assert Private.any_stale?()

    expect(FarmbotOS.Celery.SysCallGlue, :sync, 1, fn ->
      Private.mark_clean!(p)
    end)

    DirtyWorker.maybe_resync(0)
  end

  test "handle_http_response - other response" do
    Helpers.delete_all_points()
    Repo.delete_all(LocalMeta)
    Repo.delete_all(FbosConfig)
    p = Helpers.create_point(%{id: 2, pointer_type: "Weed"})

    t = fn ->
      DirtyWorker.handle_http_response(p, Point, {:error, :other})
    end

    assert capture_log(t) =~ "HTTP Error: {:error, :other}"
  end

  test "handle_http_response - 409 response" do
    Helpers.delete_all_points()
    Repo.delete_all(LocalMeta)
    Repo.delete_all(FbosConfig)

    conf =
      FarmbotOS.Asset.fbos_config()
      |> FbosConfig.changeset()
      |> Repo.insert!()

    expect(FarmbotOS.Celery.SysCallGlue, :sync, 1, fn ->
      "I expect a 409 response to trigger a sync."
    end)

    expect(Private, :recover_from_row_lock_failure, 1, fn ->
      "I expect a 409 response to trigger a row lock failure recovery."
    end)

    DirtyWorker.handle_http_response(conf, FbosConfig, {:ok, %{status: 409}})
  end

  test "maybe_resync does not run when there is *NOT* stale data" do
    Helpers.delete_all_points()
    Repo.delete_all(LocalMeta)

    stub(FarmbotOS.Celery.SysCallGlue, :sync, fn ->
      flunk("Never should call sync")
    end)

    refute(Private.any_stale?())
    refute(DirtyWorker.maybe_resync(0))
  end

  test "race condition detector: has_race_condition?(module, list)" do
    Helpers.delete_all_points()
    Repo.delete_all(LocalMeta)
    ok = Helpers.create_point(%{id: 1})
    no = Map.merge(ok, %{pullout_direction: 0})
    refute DirtyWorker.has_race_condition?(Point, [ok])
    assert DirtyWorker.has_race_condition?(Point, [no])
    refute DirtyWorker.has_race_condition?(Point, [])
  end

  test "finalize/2" do
    stub_data = %{valid?: true, anything: :rand.uniform(100)}

    expect(Repo, :update!, 1, fn data ->
      assert data == stub_data
      data
    end)

    expect(Private, :mark_clean!, 1, fn data ->
      assert data == stub_data
      data
    end)

    assert :ok == DirtyWorker.finalize(stub_data, Point)
  end
end
