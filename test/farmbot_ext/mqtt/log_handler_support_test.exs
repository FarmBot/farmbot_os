defmodule FarmbotOS.LogHandlerSupportTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Log
  alias FarmbotOS.MQTT

  alias FarmbotOS.MQTT.{
    LogHandlerSupport,
    LogHandler
  }

  # import ExUnit.CaptureLog

  @bad_log %Log{
    level: :success,
    message: "Your wifi password is foo bar baz",
    updated_at: ~N[2021-03-26 19:40:49.322695],
    verbosity: 1
  }

  @fake_state %LogHandler{}

  test "filters 'bad words'" do
    reject(MQTT, :publish, 3)
    assert :ok = LogHandlerSupport.maybe_publish_log(@bad_log, @fake_state)
  end

  test "log broadcasting" do
    expect(MQTT, :publish, 1, fn _client_id, topic, json ->
      # assert id == 555555555
      assert topic == "bot//logs"
      {:ok, actual} = FarmbotOS.JSON.decode(json)
      assert Map.get(actual, "message") == "This is OK"
      :ok
    end)

    expect(FarmbotOS.Logger, :should_log?, 1, fn _, _ ->
      true
    end)

    ok_log =
      Log.new(%Log{
        id: 555_555_555,
        level: :success,
        message: "This is OK",
        updated_at: ~N[2021-03-26 19:40:49.322695],
        inserted_at: DateTime.utc_now(),
        verbosity: 4
      })

    LogHandlerSupport.maybe_publish_log(ok_log, @fake_state)
  end
end
