defmodule Farmbot.RPC.RequestsTest do
  use ExUnit.Case, async: true

  test("it wont crash when an unhandled rpc command comes thru") do
    bad_rpc = Farmbot.RPC.Requests.handle_request("do_a_barrel_roll",
                                      [%{"param1" => "nothing"}])
    assert(bad_rpc ==
      {:error, "Unhandled method",
      "#{inspect {"do_a_barrel_roll", [%{"param1" => "nothing"}]}}"})
  end
end
