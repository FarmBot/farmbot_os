defmodule FarmbotExt.AMQP.ChannelSupervisorTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.AMQP.ChannelSupervisor

  setup :verify_on_exit!

  test "children" do
    results = ChannelSupervisor.children(%{})
    expected = []
    assert results == expected
  end
end
