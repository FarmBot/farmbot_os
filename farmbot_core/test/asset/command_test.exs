defmodule FarmbotCore.Asset.CommandTest do
  use ExUnit.Case, async: false
  alias FarmbotCore.{Asset, Asset.Command}

  test "insert new regimen" do
    id = id()
    :ok = Command.update("Regimen", id, %{id: id, monitor: false})
    assert Asset.get_regimen(id)
  end

  test "update regimen" do
    id = id()
    :ok = Command.update("Regimen", id, %{id: id, name: "abc", monitor: false})
    :ok = Command.update("Regimen", id, %{id: id, name: "def", monitor: false})
    assert Asset.get_regimen(id).name == "def"
  end

  test "delete regimen" do
    id = id()
    :ok = Command.update("Regimen", id, %{id: id, name: "abc", monitor: false})
    :ok = Command.update("Regimen", id, nil)
    refute Asset.get_regimen(id)
  end

  test "insert new farm_event" do
    id = id()
    :ok = Command.update("FarmEvent", id, %{id: id, monitor: false})
    assert Asset.get_farm_event(id)
  end

  test "update farm_event" do
    id = id()
    regimen_id = id()
    :ok = Command.update("FarmEvent", id, %{id: id, executable_type: "Sequence", monitor: false})
    :ok = Command.update("Regimen", regimen_id, %{id: regimen_id, monitor: false})

    :ok =
      Command.update("FarmEvent", id, %{
        id: id,
        executable_type: "Regimen",
        executable_id: regimen_id,
        monitor: false
      })

    assert Asset.get_farm_event(id).executable_type == "Regimen"
  end

  test "delete farm_event" do
    id = id()

    :ok =
      Command.update("FarmEvent", id, %{id: id, executable_id: id(), name: "abc", monitor: false})

    :ok = Command.update("FarmEvent", id, nil)
    refute Asset.get_farm_event(id)
  end

  defp id, do: :rand.uniform(10_000_000)
end
