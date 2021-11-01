defmodule FarmbotOS.PingHandlerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.{MQTT, Time}
  alias FarmbotOS.MQTT.{PingHandler}
  @fake_client "my_client_id"

  @fake_state %PingHandler{
    client_id: @fake_client,
    last_refresh: 0
  }

  test "handle_info - inbound ping" do
    message = {:inbound, ["bot", "device_123", "ping", "0"], "P"}

    expect(MQTT, :publish, 1, fn client_id, topic, payload ->
      assert client_id == @fake_client
      assert payload == "P"
      assert topic == "bot/device_123/pong/0"
      :ok
    end)

    expect(Time, :system_time_ms, 1, fn -> 3001 end)

    result = PingHandler.handle_info(message, @fake_state)
    expected = {:noreply, %{@fake_state | last_refresh: 3001}}
    assert result == expected
  end
end
