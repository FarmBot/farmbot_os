defmodule FarmbotExt.MQTT.SupportTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotExt.MQTT.Support

  test "forward_message" do
    msg = {"topic", "message"}
    assert nil == Support.forward_message(nil, msg)
    pid = NoOp.new()
    Support.forward_message(pid, msg)
    assert NoOp.last_message(pid) == {:inbound, "topic", "message"}
    NoOp.stop(pid)
  end
end
