defmodule FarmbotExt.AMQP.LogChannelTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.LogChannel
  alias FarmbotExt.AMQP.Support
  alias FarmbotCore.BotState

  @jwt %FarmbotExt.JWT{bot: "device_#{Enum.random(1000..100_000)}"}

  test "channel termination" do
    fake_reason = :just_testing
    fake_state = {:fake_state}

    expect(Support, :handle_termination, 1, fn reason, state, name ->
      assert reason == fake_reason
      assert state == fake_state
      assert name == "Log"
      :ok
    end)

    LogChannel.terminate(fake_reason, fake_state)
  end

  test "init" do
    expect(Support, :create_channel, 1, fn ->
      {:ok, {:fake_conn, :fake_chan}}
    end)

    expect(BotState, :subscribe, 1, fn ->
      %{fake: :state}
    end)

    expect(FarmbotCore.Logger, :handle_all_logs, fn ->
      []
    end)

    {:ok, pid} = LogChannel.start_link([jwt: @jwt], [])
    state = :sys.get_state(pid)
    %{chan: chan, conn: conn, jwt: jwt, state_cache: state_cache} = state
    assert :fake_chan == chan
    assert :fake_conn == conn
    assert @jwt == jwt
    assert %{fake: :state} == state_cache
  end
end
