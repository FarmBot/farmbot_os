defmodule FarmbotExt.LogHandlerSupportTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotCore.Log
  alias FarmbotExt.MQTT

  alias FarmbotExt.MQTT.{
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
end
