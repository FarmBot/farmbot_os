defmodule Farmbot.BotState.AuthorizationTest do
  use ExUnit.Case, async: true
  defp get_state do
    Process.sleep(10)
    StateDebugger.state
    |> Map.get(:authorization)
  end

  test "makes sure bad calls/casts dont modify state" do
    old = get_state
    GenServer.cast(Farmbot.BotState.Authorization, :self_destruct)
    bla = GenServer.call(Farmbot.BotState.Authorization, :wait_for_paint_to_dry)
    assert bla == :unhandled
    new = get_state
    assert old == new
  end
end
