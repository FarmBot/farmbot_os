defmodule Farmbot.CeleryScript.Command.ReadAllParamsTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.{Ast, Command}

  setup_all do
    Farmbot.Serial.HandlerTest.wait_for_serial_available()
    :ok
  end

  test "makes sure we have serial" do
    assert Farmbot.Serial.Handler.available?() == true
  end

  test "reads all params" do
    # old = Farmbot.BotState.get_all_mcu_params
    Command.read_all_params(%{}, [], Ast.Context.new())
    Process.sleep(100)
    new = Farmbot.BotState.get_all_mcu_params
    assert is_map(new)
    assert !Enum.empty?(new)
  end
end
