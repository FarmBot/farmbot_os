ExUnit.start
defmodule RPCMessageManagerTest do
  use ExUnit.Case, async: true

  test("it wont crash when an unhandled rpc command comes thru") do
    bad_rpc = RPCMessageHandler.do_handle("do_a_barrel_roll", [%{"param1" => "nothing"}])
    assert(bad_rpc == {:error, "Unhandled method", "#{inspect {"do_a_barrel_roll", [%{"param1" => "nothing"}]}}"})
  end

  test("it creates a JsonRpc compliant farmbot ack message") do
    msg = RPCMessageHandler.ack_msg("long uuid string")
    {:ok, decoded} = Poison.decode(msg)
    assert(Map.get(decoded, "id") == "long uuid string")
    assert(Map.get(decoded, "error") == nil)
    assert(Map.get(decoded, "result") == "OK")
  end

  test("it creates a JsonRpc compliant farmbot error message") do
    msg = RPCMessageHandler.ack_msg("long uuid again", {"error name", "error message"})
    {:ok, decoded} = Poison.decode(msg)
    assert(Map.get(decoded, "id") == "long uuid again")
    assert(Map.get(decoded, "error") == %{"name" => "error name", "message" => "error message"})
    assert(Map.get(decoded, "result") == nil)
  end

  test("it creates a JsonRpc compliant farmbot log message") do
    msg = RPCMessageHandler.log_msg("super importand log message")
    {:ok, decoded} = Poison.decode(msg)
    params = Map.get(decoded, "params")
    assert(Map.get(decoded, "id") == nil)
    assert(Map.get(decoded, "method") == "log_message")
    assert(is_list(params))
    assert(Map.get(List.first(params), "message") == "super importand log message")
  end
end
