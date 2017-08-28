defmodule Farmbot.BotState.Transport.GenMqttTest do
  use ExUnit.Case, async: false

  alias Farmbot.BotState.Transport.GenMqtt

  @moduletag [farmbot_api: true, farmbot_mqtt: true]

  import Mock

  setup_all do
    bss = Farmbot.BotStateSupport.start_bot_state_stack
    token = Application.get_env(:farmbot, :authorization)[:token] || flunk("No token in environment.")
    {:ok, Map.put(bss, :token, token)}
  end

  test "starts the mqtt client", ctx do
    name = __ENV__.function |> elem(0)
    r = GenMqtt.start_link(ctx.token, ctx.bot_state, name)
    assert match?({:ok, _}, r)
    {:ok, pid} = r
    assert is_pid(pid)
    assert Process.whereis(name) == pid
  end

  describe "integrations with bot state" do
    setup ctx do
      assert Process.alive?(ctx.bot_state)
      name = __ENV__.function |> elem(0)
      {:ok, mqtt_client} = GenMqtt.start_link(ctx.token, ctx.bot_state, name)
      wait_for_connected(mqtt_client)
      {:ok, Map.put(ctx, :mqtt, mqtt_client)}
    end

    test "ensures connection", ctx do
      assert get_state(ctx.mqtt).connected
    end

    test "logs a message", ctx do
      log = %Farmbot.Log{}
      msg = Poison.encode!(log)
      with_mock GenMQTT, [:passthrough], [
        publish: fn(_pid, _topics, _data, _qos, _bool) -> :ok end]
        do
          GenMQTT.cast(ctx.mqtt, {:log, log})
          Process.sleep(100) # this and the below test shoudl probably be calls.
          assert called(GenMQTT.publish(ctx.mqtt, :_,  msg, 0, false))
      end
    end

    test "emits a message", ctx do
      ast = %Farmbot.CeleryScript.Ast{kind: "hello", args: %{}, body: []}
      msg = Poison.encode!(ast)
      with_mock GenMQTT, [:passthrough], [
        publish: fn(_pid, _topics, _data, _qos, _bool) -> :ok end]
        do
          GenMQTT.cast(ctx.mqtt, {:emit, ast})
          Process.sleep(100)
          assert called(GenMQTT.publish(ctx.mqtt, :_,  msg, 0, false))
      end
    end

    test "pushes status updates when the bot's state updates", ctx do
      assert get_state(ctx.mqtt).connected
      msg = {:bot_state, %Farmbot.BotState{}}
      enc = Poison.encode!(%Farmbot.BotState{})
      with_mock GenMQTT, [:passthrough], [publish: fn(_pid, _topics, _data, _qos, _bool) -> :ok end] do
        send(ctx.mqtt, msg)
        Process.sleep(100)
        assert called(GenMQTT.publish(ctx.mqtt, :_,  enc, 0, false))
      end
    end

    defp wait_for_connected(mqtt, retries \\ 0)
    defp wait_for_connected(_, retries) when retries > 10 do
      flunk("Mqtt not connected.")
    end

    defp wait_for_connected(mqtt, retries) do
      unless get_state(mqtt).connected do
        Process.sleep(100)
        wait_for_connected(mqtt, retries + 1)
      end

      assert get_state(mqtt).connected
    end

    defp get_state(mqtt) do
      elem(:sys.get_state(mqtt), 1) |> elem(18)
    end
  end

end
