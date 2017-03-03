defmodule Farmbot.BotStateTest do
  use ExUnit.Case, async: false
  alias Farmbot.Token

  setup_all do
    unencoded = %{
      "bot" => "device_4000",
      "exp" => 123456,
      "iat" => 848585,
      "fw_update_server" => "rate_my_dog.org",
      "os_update_server" => "rate_my_dog.org",
      "jti" => "what is this?",
      "sub" => "webmin@yahoo.com",
      "mqtt" => "mqtt.att.net",
      "iss" => "http://ibm.com"
    }
    fake_token = Token.create!%{"unencoded" => unencoded, "encoded" => "asdf"}
    Process.sleep(100)
    {:ok, %{auth: fake_token}}
  end

  test("Gets the current bot position") do
    [x,y,z] = Farmbot.BotState.get_current_pos
    assert(is_integer(x) and is_integer(y) and is_integer(z))
  end

  test "Sets a new position" do
    Farmbot.BotState.set_pos(45, 123, -666)
    [x,y,z] = Farmbot.BotState.get_current_pos
    assert(x == 45)
    assert(y == 123)
    assert(z == -666)
  end

  test "sets a pin mode" do
    Farmbot.BotState.set_pin_mode(123, 0)
    %{mode: mode, value: _} = Farmbot.BotState.get_pin(123)
    assert(mode == 0)
  end

  test "sets a pin value" do
    Farmbot.BotState.set_pin_value(123, 55)
    %{mode: _, value: value} = Farmbot.BotState.get_pin(123)
    assert(value == 55)
  end

  test "updates tons of configs" do
    true = Farmbot.BotState.update_config("os_auto_update", false)
    os_auto_update = Farmbot.BotState.get_config(:os_auto_update)
    assert(os_auto_update == false)

    true = Farmbot.BotState.update_config("fw_auto_update", false)
    fw_auto_update = Farmbot.BotState.get_config(:fw_auto_update)
    assert(fw_auto_update == false)

    true = Farmbot.BotState.update_config("steps_per_mm_x", 123)
    true = Farmbot.BotState.update_config("steps_per_mm_y", 456)
    true = Farmbot.BotState.update_config("steps_per_mm_z", 789)

    x = Farmbot.BotState.get_config(:steps_per_mm_x)
    y = Farmbot.BotState.get_config(:steps_per_mm_y)
    z = Farmbot.BotState.get_config(:steps_per_mm_z)
    assert([x,y,z] == [123,456,789])

    fail = Farmbot.BotState.update_config("self_destruct_count_down", 10_000)
    assert(fail == false)
  end

  test "gets the current os version" do
    # i just want the coverage report ok
    os = Farmbot.BotState.get_os_version
    assert(is_bitstring(os))
  end

  test "sets end stops" do
    es = {1,1,1,1,1,1}
    Farmbot.BotState.set_end_stops(es)
    assert(get_hardware_part(:end_stops) == es)
  end

  test "gets all the mcu params" do
    assert get_hardware_part(:mcu_params) == Farmbot.BotState.get_all_mcu_params
  end

  test "sets some farmware env vars" do
    r = Farmbot.BotState.set_user_env(%{"SUPER_COOL_VAR" => 123})
    assert(r == true)
    abc = Farmbot.BotState.set_user_env("DIFFERENT_COOL_VAR", "String value")
    assert(abc == true)
  end

  test "locks the bot then unlocks it" do
    :ok = Farmbot.BotState.lock_bot
    stuffA = get_config_part(:informational_settings)[:locked]
    lockedA? = Farmbot.BotState.locked?
    assert stuffA == true
    assert stuffA == lockedA?

    :ok = Farmbot.BotState.unlock_bot
    stuffB = get_config_part(:informational_settings)[:locked]
    lockedB? = Farmbot.BotState.locked?
    assert stuffB == false
    assert stuffB == lockedB?
  end

  test "sets sync msg to :synced" do
    :ok = Farmbot.BotState.set_sync_msg(:synced)
    thing = get_config_part(:informational_settings)[:sync_status]
    assert thing == :synced
  end

  test "sets sync msg to :sync_now" do
    :ok = Farmbot.BotState.set_sync_msg(:sync_now)
    thing = get_config_part(:informational_settings)[:sync_status]
    assert thing == :sync_now
  end

  test "sets sync msg to :syncing" do
    :ok = Farmbot.BotState.set_sync_msg(:syncing)
    thing = get_config_part(:informational_settings)[:sync_status]
    assert thing == :syncing
  end

  test "sets sync msg to :sync_error" do
    :ok = Farmbot.BotState.set_sync_msg(:sync_error)
    thing = get_config_part(:informational_settings)[:sync_status]
    assert thing == :sync_error
  end

  test "sets sync msg to :unknown" do
    :ok = Farmbot.BotState.set_sync_msg(:unknown)
    thing = get_config_part(:informational_settings)[:sync_status]
    assert thing == :unknown
  end

  test "raises an error if wrong sync message" do
    assert_raise(FunctionClauseError, fn() ->
      Farmbot.BotState.set_sync_msg("some str?")
    end)
  end

  defp get_hardware_part(part) do
    Process.sleep(10)
    Farmbot.BotState.Monitor.get_state
    |> Map.get(:hardware)
    |> Map.get(part)
  end

  defp get_config_part(part) do
    Process.sleep(10)
    Farmbot.BotState.Monitor.get_state
    |> Map.get(:configuration)
    |> Map.get(part)
  end
end
