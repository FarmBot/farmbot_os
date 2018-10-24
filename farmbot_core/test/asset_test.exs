defmodule Farmbot.AssetTest do
  use ExUnit.Case, async: false
  alias Farmbot.Asset
  alias Asset.{
    SyncCmd,
    Sequence,
  }
  alias Asset.Repo.Snapshot.Diff

  defp id, do: :rand.uniform(16384)

  test "registers sync commands and syncs" do
    id = id()
    refute Asset.get_sequence_by_id(id)
    Farmbot.Registry.subscribe()
    seq = %Sequence{
      name: "test sequence",
      kind: "sequence",
      args: %{},
      body: [],
      id: id
    }
    %SyncCmd{} = sync_cmd = Asset.register_sync_cmd(id, "Sequence", seq)
    assert sync_cmd.remote_id == id
    assert sync_cmd.kind == "Sequence"
    assert sync_cmd.body == seq
    Asset.apply_sync_cmd(sync_cmd)
    from_db = Asset.get_sequence_by_id(id)
    # make sure the status and diff is dispatched.
    assert_receive {Farmbot.Registry, {Asset, {:sync_status, :syncing}}}
    assert_receive {Farmbot.Registry, {Asset, {:sync_diff, %Diff{additions: [^from_db]}}}}
    assert_receive {Farmbot.Registry, {Asset, {:sync_status, :synced}}}
    # make sure the sync cmd was deleted.
    assert sync_cmd.id not in Enum.map(Asset.all_sync_cmds(), &Map.get(&1, :id))
  end

  test "won't apply sync_cmd of unknown kind" do
    asset = %{id: id(), data: "hey!", value: []}
    cmd = Asset.register_sync_cmd(asset.id, "Whoops", asset)
    Farmbot.Registry.subscribe()
    Asset.apply_sync_cmd(cmd)
    # make sure sync status doesn't change to  syncing and no diff was dispatched.
    refute_receive {Farmbot.Registry, {Asset, {:sync_status, :syncing}}}
    refute_receive {Farmbot.Registry, {Asset, {:sync_status, :synced}}}
    refute_receive {Farmbot.Registry, {Asset, {:sync_status, :synced}}}
    refute_receive {Farmbot.Registry, {Asset, {:sync_diff, %Diff{}}}}
    # make sure the sync cmd was deleted.
    assert cmd.id not in Enum.map(Asset.all_sync_cmds(), &Map.get(&1, :id))
  end

  test "applies multiple sync cmds" do
    seq = %{id: id(), name: "test", kind: "sequence", args: %{}, body: []}
    tool = %{id: id(), name: "testtool"}
    Asset.register_sync_cmd(seq.id, "Sequence", seq)
    Asset.register_sync_cmd(tool.id, "Tool", tool)
    Farmbot.Registry.subscribe()
    Asset.fragment_sync()
    assert_receive {Farmbot.Registry, {Asset, {:sync_status, :syncing}}}
    assert_receive {Farmbot.Registry, {Asset, {:sync_status, :synced}}}
    assert_receive {Farmbot.Registry, {Asset, {:sync_status, :synced}}}
    assert_receive {Farmbot.Registry, {Asset, {:sync_diff, %Diff{additions: [tool_from_db, seq_from_db]}}}}
    assert seq.id == seq_from_db.id
    assert tool.id == tool_from_db.id
  end

  test "sync cmds with empty body remove asset" do
    seq = %{id: id(), name: "test", kind: "sequence", args: %{}, body: []}
    cmd_insert = Asset.register_sync_cmd(seq.id, "Sequence", seq)
    Asset.apply_sync_cmd(cmd_insert)
    cmd_delete = Asset.register_sync_cmd(seq.id, "Sequence", nil)
    Asset.apply_sync_cmd(cmd_delete)
    refute Asset.get_sequence_by_id(seq.id)
  end

  test "Sync cmd updates existing  data" do
    seq = %{id: id(), name: "test", kind: "sequence", args: %{}, body: []}
    cmd_insert = Asset.register_sync_cmd(seq.id, "Sequence", seq)
    Asset.apply_sync_cmd(cmd_insert)
    cmd_update = Asset.register_sync_cmd(seq.id, "Sequence", %{name: "New name!"})
    Asset.apply_sync_cmd(cmd_update)
    assert Asset.get_sequence_by_id(seq.id).name == "New name!"
  end

  describe "Sequence" do
    test "inserts a sequence" do
      seq = %{id: id(), name: "test", kind: "sequence", args: %{}, body: []}
      cmd_insert = Asset.register_sync_cmd(seq.id, "Sequence", seq)
      Asset.apply_sync_cmd(cmd_insert)
      assert data = Asset.get_sequence_by_id(seq.id)
      assert data == Asset.get_sequence!(seq.id)
    end

    test "raises when no sequence is to be found" do
      assert_raise RuntimeError, ~r"Could not find sequence by id", fn() ->
        Asset.get_sequence!(id())
      end
    end
  end

  describe "Device" do
    test "only allows one device total" do
      Farmbot.Asset.Repo.delete_all(Farmbot.Asset.Device)
      device = %{id: id(), name: "Magice Device!", timezone: nil}
      cmd_insert = Asset.register_sync_cmd(device.id, "Device", device)
      Asset.apply_sync_cmd(cmd_insert)
      assert Asset.device()
      device_2 = %{device | id: id()}
      cmd_insert_2 = Asset.register_sync_cmd(device_2.id, "Device", device_2)
      Asset.apply_sync_cmd(cmd_insert_2)
      assert_raise RuntimeError, ~r"There should only ever be 1 device!", fn() ->
        Asset.device()
      end
      # should delete all devices just in case.
      refute Asset.device()
    end
  end

  describe "Regimens" do
    test "inserts a regimen"
    test "inserts a regemin that uses a sequence"
    test "persistent regimens need to be unique by their start time."
  end

  describe "FarmEvents" do
    test "inserts a FarmEvent"
  end

  describe "Peripherals" do
    test "inserts a Peripheral" do
      per = %{id: id(), pin: 1, mode: 0, label: "laser beam"}
      cmd_insert = Asset.register_sync_cmd(per.id, "Peripheral", per)
      Asset.apply_sync_cmd(cmd_insert)
      assert data = Asset.get_peripheral_by_id(per.id)
      assert data.label == per.label
    end
  end

  describe "Sensors" do
    test "inserts a Sensor" do
      sensor = %{id: id(), pin: 1, mode: 0, label: "lightning"}
      cmd_insert = Asset.register_sync_cmd(sensor.id, "Sensor", sensor)
      Asset.apply_sync_cmd(cmd_insert)
      assert data = Asset.get_sensor_by_id(sensor.id)
      assert data.label == sensor.label
    end
  end

  describe "Points" do
    test "inserts a Point" do
      pnt = %{id: id(), name: "potato", x: 0, y: 101, z: -20, meta: %{}, pointer_type: "GenericPointer"}
      cmd_insert = Asset.register_sync_cmd(pnt.id, "Point", pnt)
      Asset.apply_sync_cmd(cmd_insert)
      assert data = Asset.get_point_by_id(pnt.id)
      assert data.name == pnt.name
    end
  end

  describe "Tools" do
    test "inserts a tool" do
      tool = %{id: id(), name: "warp drive"}
      tool_insert = Asset.register_sync_cmd(tool.id, "Tool", tool)
      Asset.apply_sync_cmd(tool_insert)
      assert data = Asset.get_tool_by_id(tool.id)
      assert data.name == "warp drive"
    end

    test "gets the point assosiated with a tool" do
      tool = %{id: id(), name: "trench digger"}
      point = %{id: id(), tool_id: tool.id, name: "trench digger location", x: 0, y: 0, z: 0, meta:  %{}, pointer_type: "ToolSlot"}

      _tool_insert = Asset.register_sync_cmd(tool.id, "Tool", tool)
      _point_insert = Asset.register_sync_cmd(point.id, "Point", point)
      Asset.fragment_sync()
      assert point = Asset.get_point_from_tool(tool.id)
      assert point.id == point.id
      assert point.name == "trench digger location"
    end
  end

  test "Delets all data."
  test "Snapshot from a single diff works."
  test "Inspecting a snapshot returns a nice hash."
end
