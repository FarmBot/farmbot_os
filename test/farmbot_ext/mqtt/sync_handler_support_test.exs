defmodule FarmbotOS.SyncHandlerSupportTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.MQTT.SyncHandlerSupport, as: Support
  alias FarmbotOS.MQTT.SyncHandler, as: State
  alias FarmbotOS.{BotState, JSON, Leds, Asset}
  alias FarmbotOS.MQTT
  alias FarmbotOS.EagerLoader

  @fake_state %State{
    client_id: "fboslol",
    username: "device_1",
    preloaded: true
  }

  @fake_payload %{
    "body" => %{"foo" => "bar"},
    "args" => %{"label" => "fsdfsdfsdfwer"}
  }

  test "finalize_preload(state, :ok)" do
    old_state = %{@fake_state | preloaded: false}
    expected = %{old_state | preloaded: true}

    expect(Leds, :green, 1, fn
      :solid -> :ok
      _ -> raise "wrong arguments in finalize_preload"
    end)

    expect(BotState, :set_sync_status, 1, fn
      "synced" -> :ok
      _ -> raise "wrong arguments in finalize_preload"
    end)

    result = Support.finalize_preload(old_state, :ok)
    assert result == {:noreply, expected}
  end

  test "drop_all_cache()" do
    expect(EagerLoader.Supervisor, :drop_all_cache, 1, fn ->
      raise "Intentional exception to test error handling"
    end)

    assert :ok == Support.drop_all_cache()
  end

  test "handle_asset (error)" do
    fake_kind = "Point"
    fake_id = 123
    fake_params = %{fake: :params}

    expect(BotState, :set_sync_status, 2, fn
      "synced" -> :ok
      "syncing" -> :ok
      _ -> raise "Wrong sync status"
    end)

    expect(Leds, :green, 2, fn
      :really_fast_blink -> :ok
      :solid -> :ok
    end)

    expect(Asset.Command, :update, 1, fn
      asset_kind, id, params ->
        assert asset_kind == fake_kind
        assert id == fake_id
        assert params == fake_params
        :ok
    end)

    Support.handle_asset(fake_kind, fake_id, fake_params)
  end

  test "finalize_preload(state, reason)" do
    expect(BotState, :set_sync_status, 1, fn
      "sync_error" -> :ok
      _ -> raise "Sync status is wrong"
    end)

    expect(FarmbotOS.Time, :send_after, 1, fn pid, msg, timeout ->
      assert pid == self()
      assert msg == :preload
      assert timeout == 5000
    end)

    expect(Leds, :green, 1, fn
      :slow_blink -> :ok
      _ -> raise "Wrong LED"
    end)

    assert {:noreply, @fake_state} ==
             Support.finalize_preload(@fake_state, "Something")
  end

  test "reply_to_sync_message" do
    json = JSON.encode!(@fake_payload)
    expect(Asset.Command, :update, 1, fn _, _, _ -> :ok end)

    expect(MQTT, :publish, 1, fn client_id, topic, that_json ->
      expected_json = %{
        "kind" => "rpc_ok",
        "args" => %{"label" => "fsdfsdfsdfwer"}
      }

      assert client_id == @fake_state.client_id
      assert JSON.decode!(that_json) == expected_json
      assert topic == "bot/device_1/from_device"
      :ok
    end)

    expect(BotState, :set_sync_status, 2, fn
      "synced" -> :ok
      "syncing" -> :ok
      _ -> raise "UNEXPECTED SYNC"
    end)

    expect(Leds, :green, 2, fn
      :really_fast_blink -> :ok
      :solid -> :ok
      _ -> raise "UNEXPECTED LED USE"
    end)

    Support.reply_to_sync_message(@fake_state, "Point", "123", json)
  end
end
