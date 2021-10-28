defmodule FarmbotExt.EagerLoaderTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotExt.EagerLoader
  alias FarmbotCore.Asset.Sync
  alias FarmbotExt.API.SyncGroup

  defmodule Fake do
    def __schema__(:source), do: "tools"
    def preload(_, _), do: {:ok, %{id: 123}}
  end

  test "child_spec/1" do
    opts = [[module: FarmbotExt.EagerLoaderTest.Fake]]
    actual = EagerLoader.child_spec(Fake)

    expected = %{
      id: {FarmbotExt.EagerLoader, FarmbotExt.EagerLoaderTest.Fake},
      restart: :permanent,
      shutdown: 500,
      start: {FarmbotExt.EagerLoader, :start_link, opts},
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

  test "finish_loading/1" do
    fake_errors = [1, 2, 3]
    assert [] == EagerLoader.finish_loading([])
    assert {:error, fake_errors} == EagerLoader.finish_loading(fake_errors)
  end
end
