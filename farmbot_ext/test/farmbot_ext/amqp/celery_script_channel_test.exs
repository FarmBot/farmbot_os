defmodule FarmbotExt.AMQP.CeleryScriptChannelTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.CeleryScriptChannel
  alias FarmbotExt.AMQP.Support

  defmodule FakeState do
    defstruct conn: %{fake: :conn}, chan: "fake_chan_", jwt: "fake_jwt_", cache: %{fake: :cache}
  end

  test "terminate" do
    expect(AMQP.Channel, :close, 1, fn "fake_chan_" -> :ok end)
    Helpers.expect_log("Disconnected from CeleryScript channel: \"foo\"")

    FarmbotExt.AMQP.CeleryScriptChannel.terminate("foo", %FakeState{})
  end

  test "init" do
    expect(Support, :create_queue, 1, fn q_name ->
      assert q_name == "my_bot_123_from_clients"
      {:ok, {:conn, :chan}}
    end)

    expect(Support, :bind_and_consume, 1, fn _chan, _queue, _xch, _rte ->
      :ok
    end)

    {:ok, pid} = CeleryScriptChannel.start_link([jwt: %{bot: "my_bot_123"}], [])
    Helpers.wait_for(pid)
  end

  test "handle_info(:connect_amqp, state) - nil" do
    expect(Support, :create_queue, 1, fn _ -> nil end)
    state = %FakeState{jwt: Helpers.fake_jwt_object(), chan: true, conn: true}
    {:noreply, result} = CeleryScriptChannel.handle_info(:connect_amqp, state)
    assert_receive(:connect_amqp, 100)
    refute result.chan
    refute result.conn
  end

  test "handle_info(:connect_amqp, state) - error" do
    state = %FakeState{jwt: Helpers.fake_jwt_object()}
    error = {:error, "testing"}
    expect(Support, :create_queue, 1, fn _ -> error end)

    expect(Support, :handle_error, 1, fn s, err, name ->
      assert name == "CeleryScript"
      assert err == error
      assert s == state
      {:noreply, state}
    end)

    CeleryScriptChannel.handle_info(:connect_amqp, state)
  end
end
