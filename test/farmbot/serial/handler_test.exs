defmodule Farmbot.Serial.HandlerTest do
  alias Farmbot.Serial.Handler
  use Farmbot.Test.Helpers.SerialTemplate, async: false

  describe "does serial tests" do

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
end
