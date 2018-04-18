defmodule Farmbot.Regimen.SupervisorTest do
  use ExUnit.Case, async: false

  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.PersistentRegimen
  alias Farmbot.Asset.Regimen

  test "Can't load child specs for persistent regimens that don't exist." do
    reg = %Regimen{farm_event_id: 999, id: 888, name: "heyo", regimen_items: []}
    {:ok, %PersistentRegimen{} = pr} = ConfigStorage.add_persistent_regimen(reg, Timex.now())
    assert Farmbot.Regimen.Supervisor.build_children([pr]) == []
    refute ConfigStorage.persistent_regimen(reg)
  end
end
