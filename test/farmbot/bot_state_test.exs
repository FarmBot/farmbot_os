defmodule Farmbot.BotStateTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.Ast.Context

  setup_all do
    context = Context.new()
    [cs_context: context]
  end

  test "Gets the current bot position", %{cs_context: context} do
    [x,y,z] = Farmbot.BotState.get_current_pos(context)
    assert(is_integer(x) and is_integer(y) and is_integer(z))
  end

  test "Sets a new position", %{cs_context: context} do
    Farmbot.BotState.set_pos(context, 45, 123, -666)
    [x,y,z] = Farmbot.BotState.get_current_pos(context)
    assert(x == 45)
    assert(y == 123)
    assert(z == -666)
  end

  test "sets a pin mode", %{cs_context: context} do
    Farmbot.BotState.set_pin_mode(context, 123, 0)
    %{mode: mode, value: _} = Farmbot.BotState.get_pin(context, 123)
    assert(mode == 0)
  end

  test "sets a pin value", %{cs_context: context} do
    Farmbot.BotState.set_pin_value(context, 123, 55)
    %{mode: _, value: value} = Farmbot.BotState.get_pin(context, 123)
    assert(value == 55)
  end

  test "updates tons of configs", %{cs_context: context} do
    true = Farmbot.BotState.update_config(context, "os_auto_update", false)
    os_auto_update = Farmbot.BotState.get_config(context, :os_auto_update)
    assert(os_auto_update == false)

    true = Farmbot.BotState.update_config(context, "steps_per_mm_x", 123)
    true = Farmbot.BotState.update_config(context, "steps_per_mm_y", 456)
    true = Farmbot.BotState.update_config(context, "steps_per_mm_z", 789)

    x = Farmbot.BotState.get_config(context, :steps_per_mm_x)
    y = Farmbot.BotState.get_config(context, :steps_per_mm_y)
    z = Farmbot.BotState.get_config(context, :steps_per_mm_z)
    assert([x,y,z] == [123,456,789])

    fail = Farmbot.BotState.update_config(context, "self_destruct_count_down", 10_000)
    assert(fail == false)
  end

  test "gets the current os version", %{cs_context: context} do
    # i just want the coverage report ok
    os = Farmbot.BotState.get_os_version(context)
    assert(is_bitstring(os))
  end

  test "sets end stops", %{cs_context: context} do
    es = {1,1,1,1,1,1}
    Farmbot.BotState.set_end_stops(context, es)
    assert(get_hardware_part(:end_stops, context) == es)
  end

  test "gets all the mcu params", %{cs_context: context} do
    assert get_hardware_part(:mcu_params, context) == Farmbot.BotState.get_all_mcu_params(context)
  end

  test "sets firmware version", %{cs_context: context} do
    Farmbot.BotState.set_fw_version(context, "uhhhhh")
    Process.sleep(100)
    assert Farmbot.BotState.get_fw_version(context) == "uhhhhh"
  end

  test "sets some farmware env vars", %{cs_context: context} do
    r = Farmbot.BotState.set_user_env(context, %{"SUPER_COOL_VAR" => 123})
    assert(r == true)
    abc = Farmbot.BotState.set_user_env(context, "DIFFERENT_COOL_VAR", "String value")
    assert(abc == true)
  end

  test "locks the bot then unlocks it", %{cs_context: context} do
    :ok = Farmbot.BotState.lock_bot(context)
    stuffA = get_config_part(:informational_settings, context)[:locked]
    lockedA? = Farmbot.BotState.locked?(context)
    assert stuffA == true
    assert stuffA == lockedA?

    :ok = Farmbot.BotState.unlock_bot(context)
    stuffB = get_config_part(:informational_settings, context)[:locked]
    lockedB? = Farmbot.BotState.locked?(context)
    assert stuffB == false
    assert stuffB == lockedB?
  end

  test "sets sync msg to :synced", %{cs_context: context} do
    :ok = Farmbot.BotState.set_sync_msg(context, :synced)
    thing = get_config_part(:informational_settings, context)[:sync_status]
    assert thing == :synced
  end

  test "sets sync msg to :sync_now", %{cs_context: context} do
    :ok = Farmbot.BotState.set_sync_msg(context, :sync_now)
    thing = get_config_part(:informational_settings, context)[:sync_status]
    assert thing == :sync_now
  end

  test "sets sync msg to :syncing", %{cs_context: context} do
    :ok = Farmbot.BotState.set_sync_msg(context, :syncing)
    thing = get_config_part(:informational_settings, context)[:sync_status]
    assert thing == :syncing
  end

  test "sets sync msg to :sync_error", %{cs_context: context} do
    :ok = Farmbot.BotState.set_sync_msg(context, :sync_error)
    thing = get_config_part(:informational_settings, context)[:sync_status]
    assert thing == :sync_error
  end

  test "sets sync msg to :unknown", %{cs_context: context} do
    :ok = Farmbot.BotState.set_sync_msg(context, :unknown)
    thing = get_config_part(:informational_settings, context)[:sync_status]
    assert thing == :unknown
  end

  test "raises an error if wrong sync message", %{cs_context: context} do
    assert_raise(FunctionClauseError, fn() ->
      Farmbot.BotState.set_sync_msg(context, "some str?")
    end)
  end

  defp get_hardware_part(part, context) do
    Process.sleep(10)
    :sys.get_state(context.monitor).state
    |> Map.get(:hardware)
    |> Map.get(part)
  end

  defp get_config_part(part, context) do
    Process.sleep(10)
    :sys.get_state(context.monitor).state
    |> Map.get(:configuration)
    |> Map.get(part)
  end
end
