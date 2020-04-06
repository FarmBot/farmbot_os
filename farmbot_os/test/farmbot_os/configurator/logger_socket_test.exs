defmodule FarmbotOS.Configurator.LoggerSocketTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Configurator.LoggerSocket
  setup :verify_on_exit!
  import ExUnit.CaptureLog

  test "init/2" do
    expected = {:cowboy_websocket, :foo, :bar}
    assert expected == LoggerSocket.init(:foo, :bar)
  end

  test "websocket_init" do
    assert {:ok, %{}} == LoggerSocket.websocket_init(nil)
    assert_receive :after_connect
  end

  test "websocket_handle (invalid JSON)" do
    s = %{state: :yep}
    msg = "Not JSON."
    payl = {:text, msg}
    assert {:ok, s} == LoggerSocket.websocket_handle(payl, s)
  end

  test "websocket_info/2" do
    assert capture_log(fn ->
             LoggerSocket.websocket_info(:whatever, %{})
           end) =~ "Dropping :whatever"
  end
end
