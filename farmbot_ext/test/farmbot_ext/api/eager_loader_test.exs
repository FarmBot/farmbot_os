defmodule FarmbotExt.API.EagerLoaderTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotExt.API.EagerLoader
  alias FarmbotCore.Asset.Sync
  alias FarmbotExt.API.SyncGroup

  defmodule Fake do
    def __schema__(:source), do: "tools"
    def preload(_, _), do: {:ok, %{id: 123}}
  end

  test "child_spec/1" do
    opts = [[module: FarmbotExt.API.EagerLoaderTest.Fake]]
    actual = EagerLoader.child_spec(Fake)

    expected = %{
      id: {FarmbotExt.API.EagerLoader, FarmbotExt.API.EagerLoaderTest.Fake},
      restart: :permanent,
      shutdown: 500,
      start: {FarmbotExt.API.EagerLoader, :start_link, opts},
      type: :worker
    }

    assert actual == expected
  end

  test "preload(%Sync{})" do
    # FarmbotCore.Asset.Tool
    expect(SyncGroup, :all_groups, 1, fn ->
      [Fake]
    end)

    assert [] = EagerLoader.preload(%Sync{tools: []})
  end
end
