defmodule Farmbot.Serial.HandlerTest do
  use ExUnit.Case
  alias Farmbot.Serial.Handler

  setup_all do
    GcodeMockTest.common_setup()
  end

  test "checks serial availablity", %{handler: handler} do
    bool = Handler.available?(handler)
    assert bool == true
  end

  test "gets the state", %{handler: handler, handler_nerves: nerves} do
    state = Handler.get_state(handler)
    assert state.nerves == nerves
    assert state.tty == "/dev/tnt0"
  end
end
