defmodule FarmbotExt.AMQP.BotStateChannelTest do
  use ExUnit.Case
  use Mimic

  # alias FarmbotExt.AMQP.BotStateChannel
  # alias FarmbotCore.BotState

  setup :verify_on_exit!
  setup :set_mimic_global

  test "read_status" do
    # {:ok, pid} = GenServer.start_link(BotStateChannel, [jwt: %{}])
    # expect(BotState, :fetch, 1, fn -> %{} end)
    # BotStateChannel.read_status(pid)
  end
end
