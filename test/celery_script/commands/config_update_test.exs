defmodule Farmbot.CeleryScript.Command.ConfigUpdateTest do
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

  test "sets some hardware params" do
    params = [
      Command.pair(%{label: "movement_timeout_x", value: "1000"}, []),
      Command.pair(%{label: "movement_timeout_y", value: "521"}, [])
    ]
    Command.config_update(%{package: "arduino_firmware"}, params)
    mtx = Farmbot.BotState.get_param "movement_timeout_x"
    mty = Farmbot.BotState.get_param "movement_timeout_y"

    assert mtx == 1000
    assert mty == 521
  end

  test "doesnt set hardware param values to -1" do
    old = Farmbot.BotState.get_param "movement_timeout_x"
    params = [
      Command.pair(%{label: "movement_timeout_x", value: "-1"}, []),
    ]
    Command.config_update(%{package: "arduino_firmware"}, params)
    new_mtx = Farmbot.BotState.get_param "movement_timeout_x"

    assert new_mtx != -1
    assert new_mtx == old
  end

  test "wont put garbage in the state" do
    params = [ Command.pair(%{label: "some_garbage", value: "9001"}, []) ]
    # ITS OVER NINE THOUSAND!!!    
    Command.config_update(%{package: "arduino_firmware"}, params)
    conf = Farmbot.BotState.get_param "some_garbage"
    assert is_nil(conf)
  end

  test "sets some os params" do
    params = [
      Command.pair(%{label: "steps_per_mm_x", value: 999}, []),
      Command.pair(%{label: "steps_per_mm_y", value: 40}, []),
    ]
    Command.config_update(%{package: "farmbot_os"}, params)

    spmx = Farmbot.BotState.get_config(:steps_per_mm_x)
    spmy = Farmbot.BotState.get_config(:steps_per_mm_y)

    assert spmx == 999
    assert spmy == 40
  end
end
