defmodule FarmbotOS.MQTT.SupportTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.MQTT.Support

  test "forward_message" do
    msg = {"topic", "message"}
    assert nil == Support.forward_message(nil, msg)
    pid = NoOp.new(name: :forward_message_stub)
    Support.forward_message(pid, msg)
    assert NoOp.last_message(pid) == {:inbound, "topic", "message"}
    Support.forward_message(:forward_message_stub, {"topicb", "by name"})
    assert NoOp.last_message(pid) == {:inbound, "topicb", "by name"}
    NoOp.stop(pid)
  end
end
