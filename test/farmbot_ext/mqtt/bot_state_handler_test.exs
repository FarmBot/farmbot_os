defmodule FarmbotOS.BotStateHandlerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.MQTT
  alias FarmbotOS.MQTT.BotStateHandler

  import ExUnit.CaptureLog

  setup :verify_on_exit!

  test "unhandled messages" do
    boom = fn -> BotStateHandler.handle_info(:lol, %{}) end
    assert capture_log(boom) =~ "UNEXPECTED HANDLE_INFO: :lol"
  end

  test "read_status" do
    BotStateHandler.read_status(self())
    assert_receive({:"$gen_cast", :reload}, 500)
  end

  test "broadcast!/1 - diff available" do
    last_state = %BotStateHandler{last_broadcast: nil}

    expect(MQTT, :publish, 1, fn client_id, topic, json ->
      assert client_id == "NOT_SET"
      assert topic == "bot/NOT_SET/status"
      # Ensure that it's a bot state.
      # The sync_status is not actually important.
      assert json =~ "sync_status"
    end)

    next_state = BotStateHandler.broadcast!(last_state)
    next_next_state = BotStateHandler.broadcast!(next_state)
    assert next_state == next_next_state
  end
end
