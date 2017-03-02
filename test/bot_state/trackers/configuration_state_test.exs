defmodule Farmbot.BotState.ConfigurationTest do
  use ExUnit.Case, async: false

  test "makes sure we dont mess state up with bad calls or casts" do
    before_call = get_state()
    resp = GenServer.call(Farmbot.BotState.Configuration, :do_a_barrel_roll)
    after_call = get_state()
    assert(resp == :unhandled)
    assert(after_call == before_call)

    GenServer.cast(Farmbot.BotState.Configuration, :bot_net_start)
    after_cast = get_state()
    assert(before_call == after_cast)
  end

  test "updates a setting inside informational settings" do
    old = get_state()
    GenServer.cast(Farmbot.BotState.Configuration,
                    {:update_info, :i_know_this, :its_unix})
    # maybe bug? change this cast to a call?
    new = get_state()
    assert(old != new)
  end

  defp get_state() do
    Process.sleep(10)
    Farmbot.BotState.Monitor.get_state() |> Map.get(:configuration)
  end
end
