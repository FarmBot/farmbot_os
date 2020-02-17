defmodule FarmbotOS.SysCalls.SendMessageTest do
  use ExUnit.Case, async: true
  use Mimic

  setup :verify_on_exit!

  alias FarmbotOS.SysCalls.SendMessage

  test "send_message" do
    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == "You are here: -1, -1, -1"
    end)
    channels = [:email]
    type = "info"
    templ = "You are here: {{ x }}, {{ y }}, {{ z }}"

    :ok = SendMessage.send_message(type, templ, channels)
  end
end
