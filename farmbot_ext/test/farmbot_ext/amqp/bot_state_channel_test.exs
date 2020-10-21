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

  test "read_status" do
    BotStateChannel.read_status(self())
    assert_receive({:"$gen_cast", :force}, 100)
  end

  test ":timeout loop - has a channel object" do
    state = %{chan: %{}}
    reply = {:noreply, state, {:continue, :dispatch}}
    assert reply == BotStateChannel.handle_info(:timeout, state)
  end

  test "handle_info({BotState, change}, state)" do
    state = %{cache: nil}
    change = %Ecto.Changeset{}
    actual = BotStateChannel.handle_info({FarmbotCore.BotState, change}, state)
    expected = {:noreply, %{cache: nil}, {:continue, :dispatch}}
    assert expected == actual
  end

  test "handle_cast(:force, state)" do
    state = %{cache: nil}
    expect(FarmbotCore.BotState, :fetch, 1, fn -> true end)
    expected = {:noreply, %{cache: true}, {:continue, :dispatch}}
    actual = BotStateChannel.handle_cast(:force, state)
    assert expected == actual
  end

  # Does not do much, just an empty loop
  test "handle_continue(:dispatch, %{chan: nil} = state)" do
    state = %{chan: nil}
    expected = {:noreply, state, 0}
    actual = BotStateChannel.handle_continue(:dispatch, state)
    assert expected == actual
  end
end
