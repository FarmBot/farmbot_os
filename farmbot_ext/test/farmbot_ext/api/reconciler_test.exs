defmodule FarmbotExt.API.ReconcilerTest do
  require Helpers
  use ExUnit.Case
  use Mimic

  alias FarmbotExt.API.Reconciler

  alias FarmbotExt.API

  setup :verify_on_exit!

  @fake_sync %Ecto.Changeset{
    action: nil,
    changes: %{
      devices: [],
      farmware_envs: [],
      fbos_configs: [],
      firmware_configs: [],
      first_party_farmwares: [],
      peripherals: [],
      point_groups: [],
      points: [],
      regimens: [],
      sensors: [],
      sequences: [],
      tools: []
    },
    errors: [],
    data: %FarmbotCore.Asset.Sync{},
    valid?: true
  }

  test "sync/0" do
    FarmbotExt.API

    nope = fn -> [] end
    expect(FarmbotExt.API.SyncGroup, :group_0, 1, nope)
    expect(FarmbotExt.API.SyncGroup, :group_1, 1, nope)
    expect(FarmbotExt.API.SyncGroup, :group_2, 1, nope)
    expect(FarmbotExt.API.SyncGroup, :group_3, 1, nope)
    expect(FarmbotExt.API.SyncGroup, :group_4, 1, nope)

    expect(API, :get_changeset, 1, fn mod ->
      assert mod == FarmbotCore.Asset.Sync
      {:ok, @fake_sync}
    end)

    assert :ok == Reconciler.sync()
  end
end
