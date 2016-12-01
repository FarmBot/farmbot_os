defmodule Farmbot.BotStateTest do
  use ExUnit.Case, async: false
  use Syncables
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
    send Farmbot.BotState.Authorization, {:authorization, fake_token}
    Process.sleep(10)
    {:ok, %{auth: fake_token}}
  end

  test("Gets the current bot position") do
    [x,y,z] = Farmbot.BotState.get_current_pos
    assert(is_integer(x) and is_integer(y) and is_integer(z))
  end

  test("Sets a new position") do
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
    Farmbot.BotState.update_config("os_auto_update", false)
    os_auto_update = Farmbot.BotState.get_config(:os_auto_update)
    assert(os_auto_update == false)

    Farmbot.BotState.update_config("fw_auto_update", false)
    fw_auto_update = Farmbot.BotState.get_config(:fw_auto_update)
    assert(fw_auto_update == false)

    Farmbot.BotState.update_config("timezone", "we dont even check this")
    timezone = Farmbot.BotState.get_config(:timezone)
    assert(timezone == "we dont even check this")

    Farmbot.BotState.update_config("steps_per_mm", 9001)
    steps_per_mm = Farmbot.BotState.get_config(:steps_per_mm)
    assert(steps_per_mm == 9001)

    fail = Farmbot.BotState.update_config("self_destruct_count_down", 10_000)
    assert(fail == false)
  end

  test "gets the current os version" do
    # i just want the coverage report ok
    os = Farmbot.BotState.get_os_version
    assert(is_bitstring(os))
  end

  test "sets and removes a lock" do
    Farmbot.BotState.add_lock("e_stop")
    v = Farmbot.BotState.get_lock("e_stop")
    assert(is_integer(v))

    Farmbot.BotState.remove_lock("e_stop")
    v = Farmbot.BotState.get_lock("e_stop")
    assert(v == nil)
  end

  test "sets a lock and fails to set the same lock again" do
    str = "Bot doesnt work on christmas."
    Farmbot.BotState.add_lock(str)
    old_locks = get_locks

    Farmbot.BotState.add_lock(str)
    new_locks = get_locks
    assert(new_locks == old_locks)
  end

  defp get_locks do
    # this is because the tracker modules arent that fast
    # and other than testing there is not a use case where
    # one needs to set a value (with a cast)
    # and then get a value right after that (with a call)
    # if i start needing to do this in production code i will handle it then.
    Process.sleep(10)
    StateDebugger.state
    |> Map.get(:configuration)
    |> Map.get(:locks)
  end

  test "fails to remove a locl" do
    fail = Farmbot.BotState.remove_lock("my dog stepped on my bot")
    assert(fail == {:error, :no_index})
  end

  test "sets end stops" do
    es = {1,1,1,1,1,1}
    Farmbot.BotState.set_end_stops(es)
    assert(get_hardware_part(:end_stops) == es)
  end

  test "gets all the mcu params" do
    assert get_hardware_part(:mcu_params) == Farmbot.BotState.get_all_mcu_params
  end

  defp get_hardware_part(part) do
    Process.sleep(10)
    StateDebugger.state
    |> Map.get(:hardware)
    |> Map.get(part)
  end

  test "gets the most recent token" do
    assert get_auth_part(:token) == Farmbot.BotState.get_token
  end

  test "gets the api server url", context do
    assert context.auth.unencoded.iss == Farmbot.BotState.get_server
  end

  test "adds credentials to auth" do
    Farmbot.BotState.add_creds({"connor@farmbot.io", "plaintext_pass", "http://ibm.com"})
    interim = get_auth_part(:interim)
    assert interim.email == "connor@farmbot.io"
    assert interim.pass == "plaintext_pass"
  end

  defp get_auth_part(part) do
    Process.sleep(10)
    StateDebugger.state
    |> Map.get(:authorization)
    |> Map.get(part)
  end

end
