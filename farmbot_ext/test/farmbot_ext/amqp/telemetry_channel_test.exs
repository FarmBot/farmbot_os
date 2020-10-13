defmodule FarmbotExt.AMQP.TelemetryChannelTest do
  require Helpers

  use ExUnit.Case, async: false
  use Mimic
  setup :verify_on_exit!
  setup :set_mimic_global
  alias FarmbotExt.AMQP.TelemetryChannel
  alias FarmbotExt.AMQP.Support

  test "channel termination" do
    fake_reason = :just_testing
    fake_state = {:fake_state}

    expect(Support, :handle_termination, 1, fn reason, state, name ->
      assert reason == fake_reason
      assert state == fake_state
      assert name == "Telemetry"
      :ok
    end)

    TelemetryChannel.terminate(fake_reason, fake_state)
  end

  test "init failure" do
    expect(FarmbotExt.AMQP.Support, :create_queue, 1, fn _ ->
      {:error, :writing_a_test}
    end)

    expect(FarmbotExt.AMQP.Support, :handle_error, 1, fn state, err, chan ->
      assert err == {:error, :writing_a_test}
      assert chan == "Telemetry"
      {:noreply, %{state | conn: nil, chan: nil}}
    end)

    {:ok, pid} = TelemetryChannel.start_link([jwt: Helpers.fake_jwt_object()], [])
    %{conn: conn, chan: chan} = :sys.get_state(pid)
    refute conn
    refute chan
  end
end
