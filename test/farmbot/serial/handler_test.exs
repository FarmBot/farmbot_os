defmodule Farmbot.Serial.HandlerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Farmbot.Serial.Handler
  # alias Farmbot.CeleryScript.Command

  setup_all do
    Farmbot.Test.SerialHelper.full_setup()
  end

  test "checks serial availablity", %{cs_context: context} do
    bool = Handler.available?(context.serial)
    assert bool == true
  end

  test "gets the state", %{cs_context: context} do
    state = :sys.get_state(context.serial)
    assert is_pid(state.nerves)
    assert is_binary(state.tty)
  end
end
