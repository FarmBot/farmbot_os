defmodule FarmbotOS.Asset.CommandTest do
  use ExUnit.Case

  alias FarmbotOS.{
    Asset,
    Asset.Device,
    Asset.FbosConfig,
    Asset.FirmwareConfig,
    Asset.Command
  }

  def reset_configs!() do
    assets = [
      FarmbotOS.Asset.Private.LocalMeta,
      FarmbotOS.Asset.FbosConfig,
      FarmbotOS.Asset.FirmwareConfig,
      FarmbotOS.Asset.Sequence,
      FarmbotOS.Asset.RegimenInstance,
      FarmbotOS.Asset.Regimen,
      FarmbotOS.Asset.FarmEvent
    ]

    Enum.map(assets, &FarmbotOS.Asset.Repo.delete_all/1)
  end

  test "update / destroy firmware config" do
    params = %{
      id: 23,
      movement_invert_motor_x: 12.34
    }

    :ok = Command.update(FirmwareConfig, 23, params)
    config = Enum.at(Asset.Repo.all(FirmwareConfig), 0)
    assert config.movement_invert_motor_x == params[:movement_invert_motor_x]

    :ok = Command.update(FirmwareConfig, 23, nil)
    next_config = Enum.at(Asset.Repo.all(FirmwareConfig), 0)
    refute next_config

    # Restore config to old value
    :ok = Command.update(FirmwareConfig, 23, Map.from_struct(config))
  end

  @tag :capture_log
  test "update / destroy fbos config" do
    reset_configs!()
    params = %{id: 23, os_auto_update: false}
    :ok = Command.update(FbosConfig, 23, params)
    config = Enum.at(Asset.Repo.all(FbosConfig), 0)
    assert config.os_auto_update == params[:os_auto_update]

    :ok = Command.update(FbosConfig, 23, nil)
    next_config = Enum.at(Asset.Repo.all(FbosConfig), 0)
    refute next_config
  end

  @tag :capture_log
  test "update / destroy device" do
    params = %{id: 23, name: "Old Device"}
    :ok = Command.update(Device, 23, params)
    device = Enum.at(Asset.Repo.all(Device), 0)
    assert device.name == params[:name]

    :ok = Command.update(Device, 23, nil)
    next_device = Enum.at(Asset.Repo.all(Device), 0)
    refute next_device
    :ok = Command.update(Device, 23, Map.from_struct(device))
  end

  test "insert new regimen" do
    id = id()
    :ok = Command.update("Regimen", id, %{id: id, monitor: false})
    assert Asset.get_regimen(id)
  end

  @tag :capture_log
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

  @tag :capture_log
  test "insert new farm_event" do
    id = id()
    :ok = Command.update("FarmEvent", id, %{id: id, monitor: false})
    assert Asset.get_farm_event(id)
  end

  test "update farm_event" do
    id = id()
    regimen_id = id()

    :ok =
      Command.update("FarmEvent", id, %{
        id: id,
        executable_type: "Sequence",
        monitor: false
      })

    :ok =
      Command.update("Regimen", regimen_id, %{id: regimen_id, monitor: false})

    :ok =
      Command.update("FarmEvent", id, %{
        id: id,
        executable_type: "Regimen",
        executable_id: regimen_id,
        monitor: false
      })

    assert Asset.get_farm_event(id).executable_type == "Regimen"
  end

  @tag :capture_log
  test "delete farm_event" do
    id = id()

    :ok =
      Command.update("FarmEvent", id, %{
        id: id,
        executable_id: id(),
        name: "abc",
        monitor: false
      })

    :ok = Command.update("FarmEvent", id, nil)
    refute Asset.get_farm_event(id)
  end

  defp id, do: :rand.uniform(10_000_000)
end
