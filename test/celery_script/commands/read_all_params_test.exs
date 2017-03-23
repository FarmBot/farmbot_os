defmodule Farmbot.CeleryScript.Command.ReadAllParamsTest do
  use ExUnit.Case, async: false

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  setup_all do
    GcodeMockTest.common_setup()
  end

  test "makes sure we have serial", %{handler: handler} do
    assert is_pid(handler)
    assert Farmbot.Serial.Handler.available?(handler) == true
  end

  test "reads all params", %{mock: mock} do
    old = Farmbot.BotState.get_all_mcu_params
    GcodeMockTest.invalidate_params(mock)
    Command.read_all_params(%{}, [])
    Process.sleep(100)
    new = Farmbot.BotState.get_all_mcu_params
    assert old != new
  end
end
