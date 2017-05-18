defmodule Farmbot.CeleryScript.Command.ReadAllParamsTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.Command

  setup_all do
    Farmbot.Test.SerialHelper.full_setup()
  end

  test "makes sure we have serial", %{cs_context: context} do
    assert Farmbot.Serial.Handler.available?(context.serial) == true
  end

  test "reads all params", %{cs_context: context} do
    # old = Farmbot.BotState.get_all_mcu_params
    Command.read_all_params(%{}, [], context)
    Process.sleep(100)
    new = Farmbot.BotState.get_all_mcu_params
    assert is_map(new)
    assert !Enum.empty?(new)
  end
end
