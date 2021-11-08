defmodule FarmbotOS.SysCalls.SendMessageTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  alias FarmbotOS.SysCalls.SendMessage

  test "send_message" do
    expect(FarmbotOS.SysCalls, :get_cached_position, fn ->
      [x: 1.2, y: 2.3, z: 3.4]
    end)

    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      assert log.message == "You are here: 1.2, 2.3, 3.4"
    end)

    channels = [:email]
    type = "info"
    templ = "You are here: {{ x }}, {{ y }}, {{ z }}"

    :ok = SendMessage.send_message(type, templ, channels)
  end
end
