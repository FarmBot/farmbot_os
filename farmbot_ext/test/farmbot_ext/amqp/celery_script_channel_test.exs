defmodule FarmbotExt.AMQP.CeleryScriptChannelTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic

  import ExUnit.CaptureLog

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.CeleryScriptChannel
  alias FarmbotExt.AMQP.Support
  alias FarmbotCore.JSON

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

  test "handle_info({:basic_consume_ok, _}, state)" do
    state = %{foo: :bar}
    Helpers.expect_log("Farmbot is up and running!")
    actual = CeleryScriptChannel.handle_info({:basic_consume_ok, 0}, state)
    expected = {:noreply, state}
    assert actual == expected
  end

  test "handle_info({:basic_cancel, _}, state)" do
    state = %{foo: :bar}
    actual = CeleryScriptChannel.handle_info({:basic_cancel, 0}, state)
    expected = {:stop, :normal, state}
    assert actual == expected
  end

  test "handle_info({:basic_cancel_ok, 0}" do
    state = %{foo: :bar}
    actual = CeleryScriptChannel.handle_info({:basic_cancel_ok, 0}, state)
    expected = {:noreply, state}
    assert actual == expected
  end

  test "handle_info({:basic_deliver, payload, %{routing_key: key}}, state)" do
    label = "#$#$#$#$#$#$#$#"

    fake_rpc = %{
      kind: "rpc_request",
      args: %{label: label, timeout: 99},
      body: []
    }

    state = %{rpc_requests: %{}, jwt: Helpers.fake_jwt_object()}
    key = "bot.#{state.jwt.bot}.from_clients"
    payload = JSON.encode!(fake_rpc)
    message = {:basic_deliver, payload, %{routing_key: key}}
    {:noreply, next_state} = CeleryScriptChannel.handle_info(message, state)

    rpc =
      next_state.rpc_requests
      |> Map.values()
      |> Enum.at(0)

    assert_receive({:step_complete, {:error, "timeout"}}, 100)
    assert rpc
    assert label == rpc.label
    assert is_number(rpc.started_at)
  end

  test "handle_info({:step_complete, ref, :ok}, state)" do
    label = "#$@#!@!!!"
    ref = %{fake: :ref}

    state = %{
      rpc_requests: %{ref => %{label: label, timer: nil}},
      chan: %{chan: true},
      jwt: Helpers.fake_jwt_object()
    }

    message = {:step_complete, ref, :ok}

    expect(AMQP.Basic, :publish, 1, fn chan, exch, route, reply ->
      assert chan == state.chan
      assert exch == "amq.topic"
      assert route == "bot.#{state.jwt.bot}.from_device"
      assert reply == "{\"args\":{\"label\":\"#$@#!@!!!\"},\"kind\":\"rpc_ok\"}"
      :ok
    end)

    expected_msg = "[info]  CeleryScript ok [%{fake: :ref}]"

    run_test = fn ->
      {:noreply, next_state} = CeleryScriptChannel.handle_info(message, state)
      assert next_state.rpc_requests == %{}
    end

    assert capture_log(run_test) =~ expected_msg
  end

  test "handle_info({:step_complete, ref, {:error, reason}}, state)" do
    label = "#$@#!@!!!"
    ref = %{fake: :ref}

    state = %{
      rpc_requests: %{ref => %{label: label, timer: nil}},
      chan: %{chan: true},
      jwt: Helpers.fake_jwt_object()
    }

    reason = "testing123"
    message = {:step_complete, ref, {:error, reason}}
    Helpers.expect_log("Failed to execute command: #{reason}")

    expect(AMQP.Basic, :publish, 1, fn chan, exch, route, reply ->
      assert chan == state.chan
      assert exch == "amq.topic"
      assert route == "bot.#{state.jwt.bot}.from_device"

      expected_reply = %{
        "kind" => "rpc_error",
        "args" => %{"label" => label},
        "body" => [
          %{
            "kind" => "explanation",
            "args" => %{
              "message" => "testing123"
            }
          }
        ]
      }

      assert reply == JSON.encode!(expected_reply)
      :ok
    end)

    expected_msg = "[error] CeleryScript error [%{fake: :ref}]: \"testing123\""

    run_test = fn ->
      {:noreply, next_state} = CeleryScriptChannel.handle_info(message, state)
      assert next_state.rpc_requests == %{}
    end

    assert capture_log(run_test) =~ expected_msg
  end

  test "handle_info({:step_complete, _, _}, state) - missing label" do
    state = %{rpc_requests: %{}, chan: %{}, jwt: Helpers.fake_jwt_object()}
    message = {:step_complete, nil, {:error, nil}}

    run_test = fn ->
      assert {:noreply, state} == CeleryScriptChannel.handle_info(message, state)
    end

    expected_msg = "[error] CeleryScript error [nil]: nil"
    assert capture_log(run_test) =~ expected_msg
  end
end
