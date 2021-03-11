defmodule FarmbotExt.MQTTTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotExt.MQTT
  import ExUnit.CaptureLog

  test "handle_message - MISC" do
    fake_state = %MQTT{client_id: UUID.uuid4(:hex)}
    expected_message = "Unhandled MQTT message: {\"X\", \"Y\"}"

    run_test = fn ->
      result = MQTT.handle_message("X", "Y", fake_state)
      assert result == {:ok, fake_state}
    end

    assert capture_log(run_test) =~ expected_message
  end

  test "terminate/2 callback" do
    fake_state = %MQTT{client_id: UUID.uuid4(:hex)}
    expected_message = "MQTT Connection Failed: :fake_error"

    run_test = fn ->
      result = MQTT.terminate(:fake_error, fake_state)
      assert result == :ok
    end

    assert capture_log(run_test) =~ expected_message
  end
end
