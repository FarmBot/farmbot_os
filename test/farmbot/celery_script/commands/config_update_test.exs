defmodule Farmbot.CeleryScript.Command.ConfigUpdateTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.{Command, Ast}

  setup_all do
    Farmbot.Serial.HandlerTest.wait_for_serial_available()
    [cs_context: Ast.Context.new()]
  end

  defp pair(key, val) do
    %Ast{kind: "pair", args: %{label: key, value: val}, body: []}
  end

  test "makes sure we have serial" do
    assert Farmbot.Serial.Handler.available?() == true
  end

  test "sets some hardware params",  %{cs_context: context} do
    params = [
      pair("movement_timeout_x", "1000"),
      pair("movement_timeout_y", "521")
    ]
    args = %{package: "arduino_firmware"}
    Command.config_update(args, params, context)
    mtx = Farmbot.BotState.get_param "movement_timeout_x"
    mty = Farmbot.BotState.get_param "movement_timeout_y"

    assert mtx == 1000
    assert mty == 521
  end

  test "doesnt set hardware param values to -1", %{cs_context: context} do
    old = Farmbot.BotState.get_param "movement_timeout_x"
    params = [
      pair("movement_timeout_x", "-1")
    ]
    Command.config_update(%{package: "arduino_firmware"}, params, context)
    new_mtx = Farmbot.BotState.get_param "movement_timeout_x"

    assert new_mtx != -1
    assert new_mtx == old
  end

  test "wont put garbage in the state", %{cs_context: context} do
    params = [ pair("some_garbage", "9001") ]
    # ITS OVER NINE THOUSAND!!!

    assert_raise RuntimeError, fn ->
      Command.config_update(%{package: "arduino_firmware"}, params, context)
    end

    conf = Farmbot.BotState.get_param "some_garbage"
    assert is_nil(conf)
  end

  test "sets some os params", %{cs_context: context} do
    params = [
      pair("steps_per_mm_x", 999),
      pair("steps_per_mm_y", 40),
    ]
    Command.config_update(%{package: "farmbot_os"}, params, context)

    spmx = Farmbot.BotState.get_config(:steps_per_mm_x)
    spmy = Farmbot.BotState.get_config(:steps_per_mm_y)

    assert spmx == 999
    assert spmy == 40
  end
end
