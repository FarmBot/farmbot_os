defmodule FarmbotOS.Configurator.LoggerSocketTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Configurator.LoggerSocket
  setup :verify_on_exit!

  test "init/2" do
    # TODO(Rick) Not sure what the real args are.
    # Circle back to make this test more realistic
    # later.
    expected = {:cowboy_websocket, :foo, :bar}
    assert expected == LoggerSocket.init(:foo, :bar)
  end
end
