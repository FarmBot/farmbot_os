defmodule FarmbotOS.RPCHandlerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.JSON
  alias FarmbotOS.MQTT
  alias FarmbotOS.MQTT.RPCHandler, as: RPC

  import ExUnit.CaptureLog

  @payload %{
    kind: "rpc_request",
    args: %{
      label: "a2c67bf6-d8df-4213-89c3-8508bb5363e9",
      priority: 600
    },
    body: [
      %{
        kind: "set_user_env",
        args: %{},
        body: [
          %{
            kind: "pair",
            args: %{
              label: "LAST_CLIENT_CONNECTED",
              value: "2021-03-31T19:42:18.173Z"
            }
          }
        ]
      }
    ]
  }

  test "handle_info - unknown messages" do
    misc = fn ->
      {:noreply, _next_state} = RPC.handle_info("SOMETHING ELSE", %{})
    end

    assert capture_log(misc) =~
             "FarmbotOS.MQTT.RPCHandler Uncaught message: \"SOMETHING ELSE\""
  end

  test "handle_info({:inbound, [_, _, from_clients], payload}, state)" do
    state = %RPC{
      client_id: "device_0",
      username: "device1.13.0.1",
      rpc_requests: %{}
    }

    payload = JSON.encode!(@payload)
    message = {:inbound, ["bot", "device_0", "from_clients"], payload}
    {:noreply, state2} = RPC.handle_info(message, state)
    assert state2.client_id == "device_0"
    assert state2.username == "device1.13.0.1"
    queue = Enum.map(state2.rpc_requests, fn pair -> pair end)
    assert Enum.count(queue) == 1
    {ref, rpc_record} = Enum.at(queue, 0)
    assert is_reference(ref)
    assert is_number(rpc_record.started_at)
    assert rpc_record.label
    refute rpc_record.timer
    {:noreply, state3} = RPC.handle_info({:csvm_done, ref, :ok}, state2)
    assert state3.rpc_requests == %{}
  end

  test "handle_info({:csvm_done, ref, {:error, reason}}, state)" do
    fake_ref = :fake_ref
    reason = "unit testing"
    fake_timer = "fake_timer"
    fake_label = "fake_label"

    state = %RPC{
      client_id: "device_321",
      username: "device321.13.0.1",
      rpc_requests: %{fake_ref => %{label: fake_label, timer: fake_timer}}
    }

    msg = {:csvm_done, fake_ref, {:error, reason}}

    expected_state = %FarmbotOS.MQTT.RPCHandler{
      client_id: "device_321",
      rpc_requests: %{},
      username: "device321.13.0.1"
    }

    expect(FarmbotOS.Time, :cancel_timer, 1, fn timer ->
      assert timer == fake_timer
    end)

    expect(MQTT, :publish, 1, fn client_id, topic, payload ->
      json = JSON.decode!(payload)

      expected_reply = %{
        "kind" => "rpc_error",
        "args" => %{"label" => "fake_label"},
        "body" => [
          %{
            "kind" => "explanation",
            "args" => %{"message" => "unit testing"}
          }
        ]
      }

      assert state.client_id == client_id
      assert "bot/device321.13.0.1/from_device" == topic
      assert expected_reply == json
    end)

    result = RPC.handle_info(msg, state)
    assert result == {:noreply, expected_state}
  end
end
