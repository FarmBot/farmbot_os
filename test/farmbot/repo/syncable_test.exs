defmodule Farmbot.Repo.SyncableTest do
  @moduledoc "Tests Syncable module."

  use ExUnit.Case

  test "ensures time from is8601" do
    now_dt = DateTime.utc_now()
    now_iso = now_dt |> DateTime.to_iso8601()
    obj = %{some_time: now_iso, other_time: now_iso}
    res = Farmbot.Repo.Syncable.ensure_time(obj, [:some_time, :other_time])
    assert res.some_time == now_dt
    assert res.other_time == now_dt
  end
end
