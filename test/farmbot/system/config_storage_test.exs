defmodule Farmbot.System.ConfigStorageTest do
  use ExUnit.Case, async: false

  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.PersistentRegimen

  alias Farmbot.Asset
  alias Asset.{Regimen, FarmEvent}

  test "adds a persistent regimen" do
    e = %FarmEvent{id: 90} |> Farmbot.Repo.insert!()
    r = %Regimen{id: 100, regimen_items: [], farm_event_id: e.id} |> Farmbot.Repo.insert!()
    now = Timex.now()
    {:ok, %PersistentRegimen{farm_event_id: fid, time: time, regimen_id: rid}} = ConfigStorage.add_persistent_regimen(r, now)
    assert fid == e.id
    assert time == now
    assert rid  == r.id
  end

  test "fails to add a persistent regimen without a farm_event id" do
    r = %Regimen{id: 1010, regimen_items: [], farm_event_id: nil} |> Farmbot.Repo.insert!()
    assert_raise RuntimeError, ~r"Can't save", fn() ->
      ConfigStorage.add_persistent_regimen(r, Timex.now())
    end
  end

  test "fails to add a persistent regimen if there is already one with the same info." do
    e = %FarmEvent{id: 50} |> Farmbot.Repo.insert!()
    r = %Regimen{id: 5050, regimen_items: [], farm_event_id: e.id} |> Farmbot.Repo.insert!()
    now = Timex.now()
    {:ok, %PersistentRegimen{}} = ConfigStorage.add_persistent_regimen(r, now)
    # This isn't the greatest error to receive, but whatever.
    assert_raise  Sqlite.DbConnection.Error, ~r"UNIQUE constraint", fn() ->
      ConfigStorage.add_persistent_regimen(r, now)
    end
  end

  test "gets all persistent regimens indexed by a farm event" do
    r = %Regimen{id: 220, regimen_items: []} |> Farmbot.Repo.insert!()
    now = Timex.now()
    farm_event_ids = for i <- 600..620 do
      %FarmEvent{id: i} |> Farmbot.Repo.insert!()
      {:ok, %PersistentRegimen{}} = ConfigStorage.add_persistent_regimen(%{r | farm_event_id: i}, now)
      i
    end

    prs = ConfigStorage.persistent_regimens(r)
    assert Enum.count(farm_event_ids) == Enum.count(prs)
    assert Enum.count(farm_event_ids) == 21
    assert Enum.all?(prs, fn(%PersistentRegimen{} = pr) ->
      fid = pr.farm_event_id
      assert fid in farm_event_ids
    end)
  end

  test "deletes a persistent regimen" do
    e = %FarmEvent{id: 3030} |> Farmbot.Repo.insert!()
    r = %Regimen{id: 30, regimen_items: [], farm_event_id: e.id} |> Farmbot.Repo.insert!()
    {:ok, %PersistentRegimen{}} = ConfigStorage.add_persistent_regimen(r, Timex.now())
    assert {:ok, _} = ConfigStorage.delete_persistent_regimen(r)
  end

  test "wont delete a pr if a farm_event id isn't supplied" do
    e = %FarmEvent{id: 6060} |> Farmbot.Repo.insert!()
    r = %Regimen{id: 60, regimen_items: [], farm_event_id: e.id} |> Farmbot.Repo.insert!()
    {:ok, %PersistentRegimen{}} = ConfigStorage.add_persistent_regimen(r, Timex.now())

    assert_raise RuntimeError, ~r"cannot delete", fn() ->
      ConfigStorage.delete_persistent_regimen(%{r | farm_event_id: nil})
    end
  end
end
