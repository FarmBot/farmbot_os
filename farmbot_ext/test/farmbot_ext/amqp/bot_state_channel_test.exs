defmodule FarmbotExt.AMQP.BotStateChannelTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.{
    Support,
    BotStateChannelSupport,
    BotStateChannel
  }

  defmodule FakeState do
    defstruct conn: %{fake: :conn}, chan: "fake_chan_", jwt: "fake_jwt_", cache: %{fake: :cache}
  end

  test "terminate" do
    expect(AMQP.Channel, :close, 1, fn "fake_chan_" -> :ok end)
    Helpers.expect_log("Disconnected from BotState channel: \"foo\"")
    BotStateChannel.terminate("foo", %FakeState{})
  end

  test "do_connect/2" do
    state = %{conn: 123, chan: 456}
    conn = {:ok, {:conn, :chan}}
    continue = {:continue, :dispatch}

    expect(Support, :connect_fail, 1, fn name, error ->
      assert name == "BotState"
      assert error == :error
      :ok
    end)

    {:noreply, state1, ^continue} = BotStateChannel.do_connect(conn, state)
    assert state1 == %{chan: :chan, conn: :conn}
    {:noreply, state2, 0} = BotStateChannel.do_connect(nil, state)
    assert state2 == %{chan: nil, conn: nil}
    {:noreply, state3, 0} = BotStateChannel.do_connect(:error, state)
    assert state3 == %{chan: nil, conn: nil}
  end

  test "init" do
    expect(Support, :create_channel, 1, fn ->
      {:ok, {%{conn: true}, %{chan: true}}}
    end)

    expect(BotStateChannelSupport, :broadcast_state, 1, fn _, _, _ ->
      :ok
    end)

    expect(Support, :handle_termination, 1, fn _reason, _state, _name ->
      :normal
    end)

    {:ok, pid} = BotStateChannel.start_link([jwt: Helpers.fake_jwt_object()], [])

    GenServer.stop(pid, :normal)
  end
end
