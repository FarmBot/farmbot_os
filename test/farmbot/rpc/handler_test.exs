defmodule Farmbot.RPC.HandlerTest do
  use ExUnit.Case, async: true

  test("it creates a JsonRpc compliant farmbot ack message") do
    msg = Farmbot.RPC.Handler.ack_msg("long uuid string")
    {:ok, decoded} = Poison.decode(msg)
    assert(Map.get(decoded, "id") == "long uuid string")
    assert(Map.get(decoded, "error") == nil)
    assert(Map.get(decoded, "result") == %{"OK" => "OK"})
  end

  test("it creates a JsonRpc compliant farmbot error message") do
    msg = Farmbot.RPC.Handler.ack_msg("long uuid again", {"error name", "error message"})
    {:ok, decoded} = Poison.decode(msg)
    assert(Map.get(decoded, "id") == "long uuid again")
    assert(Map.get(decoded, "error") == %{"name" => "error name", "message" => "error message"})
    assert(Map.get(decoded, "result") == nil)
  end

  test("it creates a JsonRpc compliant farmbot log message") do
    msg = Farmbot.RPC.Handler.log_msg("super important log message",
                        [:error_toast, :error_ticker],
                        ["SERIAL"])
    {:ok, decoded} = Poison.decode(msg)
    params = Map.get(decoded, "params")
    assert(Map.get(decoded, "id") == nil)
    assert(Map.get(decoded, "method") == "log_message")
    assert(is_list(params))
    assert(Map.get(List.first(params), "message") == "super important log message")
  end
end
