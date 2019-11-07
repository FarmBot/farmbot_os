defmodule FarmbotExt.API.PreloaderTest do
  use ExUnit.Case
  import Mox

  alias FarmbotCore.{
    # Asset, 
    Asset.Query,
    Asset.Sync
  }

  alias FarmbotExt.{API, API.Preloader}

  setup :verify_on_exit!

  test "get sync error" do
    expect(API, :get_changeset, fn Sync ->
      {:error, "some descriptive API error"}
    end)

    expect(Query, :first_sync?, 1, fn -> false end)

    assert {:error, "some descriptive API error"} = Preloader.preload_all()
  end
end
