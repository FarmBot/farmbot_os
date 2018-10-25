defmodule Farmbot.Asset.PersistentRegimenTest do
  use ExUnit.Case, async: false
  alias Farmbot.Asset.{
    Repo,
    FarmEvent,
    Regimen,
    PersistentRegimen
  }

  test "persistent regimen assocs" do
    regimen = %Regimen{
      id: 100,
      name: "Just a test",
      regimen_items: [],
    }
    |> Regimen.changeset()
    |> Repo.insert!()

    now = DateTime.utc_now()
    farm_event = %FarmEvent{
      start_time: now,
      end_time: now,
      executable_type: "Regimen",
      executable_id: regimen.id,
      repeat: 0,
      time_unit: "never"
    }
    |> FarmEvent.changeset()
    |> Repo.insert!()

    pr = %PersistentRegimen{
      farm_event: farm_event,
      regimen: regimen,
    }
    |> PersistentRegimen.changeset()
    |> Repo.insert!()

    assert pr.farm_event.local_id == farm_event.local_id
    assert pr.regimen.local_id == regimen.local_id
  end
end
