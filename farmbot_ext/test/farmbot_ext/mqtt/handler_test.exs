defmodule FarmbotExt.MQTT.HandlerTest do
  use ExUnit.Case
  use Mimic
  # require Helpers
  alias FarmbotExt.MQTT.Handler
  import ExUnit.CaptureLog

  test "handle_message - MISC" do
    fake_state = %Handler{client_id: UUID.uuid4(:hex)}
    expected_message = "Unhandled MQTT message: {\"X\", \"Y\"}"

    run_test = fn ->
      result = Handler.handle_message("X", "Y", fake_state)
      assert result == {:ok, fake_state}
    end

    assert capture_log(run_test) =~ expected_message
  end

  test "handle_message - PING" do
    fake_state = %Handler{client_id: UUID.uuid4(:hex), connection_status: :up}
    fake_topic = ["bot", "devie_15", "ping", "1234"]
    fake_payl = "4321"

    expect(Tortoise, :publish, 1, fn id, topic, payload, opts ->
      qos = Keyword.fetch!(opts, :qos)
      assert qos == 0
      assert payload == fake_payl
      assert topic == "bot/devie_15/pong/1234"
      assert id == fake_state.client_id
      :ok
    end)

    Handler.handle_message(fake_topic, fake_payl, fake_state)
    Handler.handle_message("X", "Y", fake_state)
  end
end
