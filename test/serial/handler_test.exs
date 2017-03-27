defmodule Farmbot.Serial.HandlerTest do
  use ExUnit.Case
  alias Farmbot.Serial.Handler

  setup_all do
    wait_for_serial_available()
    :ok
  end

  test "checks serial availablity" do
    bool = Handler.available?
    assert bool == true
  end

  test "gets the state" do
    state = Handler.get_state
    assert is_pid(state.nerves)
    assert state.tty == "/dev/tnt1"
  end

  def wait_for_serial_available do
    case Process.whereis(Handler) do
      nil ->
        Process.sleep(10)
        wait_for_serial_available()
      _ -> Farmbot.CeleryScript.Command.home(%{axis: "all"}, [])
    end
  end

end
