defmodule FarmbotExt.API.EagerLoaderTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotCore.Asset.Sync
  alias FarmbotExt.API.EagerLoader

  defmodule Fake do
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
end
