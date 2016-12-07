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
end
