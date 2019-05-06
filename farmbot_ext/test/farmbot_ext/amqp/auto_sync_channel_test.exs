
defmodule FarmbotExt.AMQP.AutoSyncChannelTest do
  use ExUnit.Case
  # import Mox

  test "Handling of :basic_consume_ok message" do
    expected_state = %{anything: "YEP"}
    {_, actual_state}= FarmbotExt
      .AMQP
      .AutoSyncChannel
      .handle_info({:basic_consume_ok, ""}, expected_state)
    assert(expected_state == actual_state)
  end
end
