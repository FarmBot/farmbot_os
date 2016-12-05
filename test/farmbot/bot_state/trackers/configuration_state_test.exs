defmodule Farmbot.BotState.ConfigurationTest do
  use ExUnit.Case, async: false
  alias Farmbot.BotState.Configuration.State, as: ConfigState

  test "makes sure we init with good usable state" do
    m = Farmbot.BotState.Configuration

    # this is the bad write. it just puts some garbage into safestorage
    # What should happen is the load function sees this as bad data, throws
    # it away and just gives the initial state back
    initial = %ConfigState{configuration: %{steps_per_mm: 6000}}
    SafeStorage.write(m, :erlang.term_to_binary(%{fake: :stuff}))
    bad_write = m.load(initial)
    assert(bad_write == initial)

    # Here we are writeing a good config state into storage so when we load it
    # again it should persist
    old = %ConfigState{configuration: %{steps_per_mm: 42}}
    SafeStorage.write(m, :erlang.term_to_binary(initial))
    good_write = m.load(old)
    assert(good_write != old)
  end

  test "makes sure we dont mess state up with bad calls or casts" do
    before_call = get_state
    resp = GenServer.call(Farmbot.BotState.Configuration, :do_a_barrel_roll)
    after_call = get_state
    assert(resp == :unhandled)
    assert(after_call == before_call)

    GenServer.cast(Farmbot.BotState.Configuration, :bot_net_start)
    after_cast = get_state
    assert(before_call == after_cast)
  end

  test "updates a setting inside informational settings" do
    old = get_state
    GenServer.cast(Farmbot.BotState.Configuration,
                    {:update_info, :i_know_this, :its_unix})
    # maybe bug? change this cast to a call?
    new = get_state
    assert(old != new)
  end

  defp get_state do
    Process.sleep(10)
    StateDebugger.state |> Map.get(:configuration)
  end
end
