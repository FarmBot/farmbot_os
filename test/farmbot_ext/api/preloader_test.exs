defmodule FarmbotOS.API.PreloaderTest do
  require Helpers

  use ExUnit.Case
  use Mimic

  alias Ecto.Changeset
  alias FarmbotOS.Asset.Sync
  alias FarmbotOS.API
  alias FarmbotOS.API.{Reconciler, Preloader}

  setup :verify_on_exit!

  test "get sync error" do
    expect(API, :get_changeset, fn Sync ->
      {:error, "some descriptive API error"}
    end)

    assert {:error, "some descriptive API error"} = Preloader.preload_all()
  end

  test "do_auto_sync" do
    expect(API, :get_changeset, fn Sync ->
      {:ok, :fake_changeset}
    end)

    expect(Reconciler, :sync_group, 5, fn _, _ -> %Changeset{valid?: true} end)
    assert :ok = Preloader.preload_all()
  end
end
