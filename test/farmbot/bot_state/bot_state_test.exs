defmodule Farmbot.BotStateTest do
  @moduledoc "Various functions to modify the bot's state"

  use ExUnit.Case, async: true
  alias Farmbot.BotState

  setup_all do
    old_state = get_state()
    {:ok, %{old_state: old_state}}
  end

  test "gets a pin value" do
    pin = BotState.get_pin_value(-1000)
    assert pin == {:error, :unknown_pin}
  end

  test "gets current position", %{old_state: _old_state} do
    pos = BotState.get_current_pos()
    assert match?(%{x: _, y: _, z: _}, pos)
  end

  test "Forces a push of the current state" do
    state = BotState.force_state_push
    assert state == get_state()
  end

  test "sets busy", %{old_state: _old_state} do
    :ok = BotState.set_busy(true)
    assert match?(true, get_state(:informational_settings).busy)
    :ok = BotState.set_busy(false)
    assert match?(false, get_state(:informational_settings).busy)
  end

  test "sets sync status :maintenance" do
    :ok = Farmbot.BotState.set_sync_status(:maintenance)
    assert match?(:maintenance, get_state(:informational_settings).sync_status)
  end

  test "sets sync status :sync_error" do
    :ok = Farmbot.BotState.set_sync_status(:sync_error)
    assert match?(:sync_error, get_state(:informational_settings).sync_status)
  end

  test "sets sync status :sync_now" do
    :ok = Farmbot.BotState.set_sync_status(:sync_now)
    assert match?(:sync_now, get_state(:informational_settings).sync_status)
  end

  test "sets sync status :synced" do
    :ok = Farmbot.BotState.set_sync_status(:synced)
    assert match?(:synced, get_state(:informational_settings).sync_status)
  end

  test "sets sync status :syncing" do
    :ok = Farmbot.BotState.set_sync_status(:syncing)
    assert match?(:syncing, get_state(:informational_settings).sync_status)
  end

  test "sets sync status :unknown" do
    :ok = Farmbot.BotState.set_sync_status(:unknown)
    assert match?(:unknown, get_state(:informational_settings).sync_status)
  end

  test "sets user environment" do
    key = "some_key"
    val = "hey! this should be in the bot's state!"
    :ok = BotState.set_user_env(key, val)
    res = BotState.get_user_env
    assert match?(%{^key => ^val}, res)
  end

  test "registers and unregisters farmware" do
    name = "Not real farmware"
    fw = Farmbot.TestSupport.FarmwareFactory.generate(name: name)
    :ok = BotState.register_farmware(fw)
    assert match?(%{^name => %{meta: %{author: _, description: _, language: _, min_os_version_major: _, version: _},
                               args: _,
                               executable: _,
                               path: _,
                               url: _}},
                  get_state(:process_info).farmwares)
    :ok = BotState.unregister_farmware(fw)
    refute Map.has_key?(get_state(:process_info).farmwares, name)
  end

  defp get_state(key \\ nil) do
    state = :sys.get_state(Farmbot.BotState).state
    if key do
      Map.get(state, key)
    else
      state
    end
  end
end
