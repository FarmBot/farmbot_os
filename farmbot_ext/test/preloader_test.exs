defmodule FarmbotExt.API.PreloaderTest do
  use ExUnit.Case
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "preload" do
    expect(MockPreloader, :preload_all, fn -> :ok end)

    assert FarmbotExt.API.Preloader.preload_all() == :ok
  end
end
