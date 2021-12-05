defmodule FarmbotOS.Firmware.UARTCoreTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotOS.Firmware.UARTCore
  alias FarmbotOS.Firmware.UARTCoreSupport, as: Support
  alias FarmbotOS.Firmware.ConfigUploader
  alias FarmbotOS.BotState

  require Helpers

  setup :set_mimic_global
  setup :verify_on_exit!

  test "watch_pin()" do
    me = self()

    expect(FarmbotOS.Firmware.Command, :watch_pin, fn pin_number ->
      assert pin_number == 54
    end)

    spawn(UARTCore, :watch_pin, [me, 54])
    assert_receive {:watch_pin, _}
  end

  test "unwatch_pin()" do
    me = self()

    expect(FarmbotOS.Firmware.Command, :watch_pin, fn pin_number ->
      assert pin_number == 0
    end)

    spawn(UARTCore, :unwatch_pin, [me])
    assert_receive :unwatch_pin
  end

  test "send_raw" do
    UARTCore.send_raw(self(), "E")
    assert_receive {:send_raw, "E"}
  end

  test "restart_firmware" do
    me = self()
    spawn(fn -> :ok = UARTCore.restart_firmware(me) end)
    assert_receive :reset_state
  end

  test "handle_info({:watch_pin, watcher}, state) - OK" do
    s1 = %{pin_watcher: nil}
    {:noreply, s2} = UARTCore.handle_info({:watch_pin, self()}, s1)
    assert s2.pin_watcher == self()
  end

  test "handle_info({:unwatch_pin, watcher}, state) - OK" do
    s1 = %{pin_watcher: self()}
    {:noreply, s2} = UARTCore.handle_info(:unwatch_pin, s1)
    assert s2.pin_watcher == nil
  end

  test "handle_info({:circuits_uart, _, {:partial, msg}}, state)" do
    Helpers.expect_log("UART timeout: :foo")
    s1 = %{}

    {:noreply, s2} =
      UARTCore.handle_info({:circuits_uart, nil, {:partial, :foo}}, s1)

    assert s2 == s1
  end

  test ":best_effort_bug_fix - KO" do
    Helpers.expect_log("Rebooting inactive Farmduino.")
    state1 = %UARTCore{fw_type: nil}

    expect(BotState, :fetch, 1, fn ->
      %{informational_settings: %{firmware_version: nil}}
    end)

    expect(FarmbotOS.Asset, :fbos_config, 1, fn ->
      %{firmware_hardware: "none"}
    end)

    {:noreply, state2} = UARTCore.handle_info(:best_effort_bug_fix, state1)
    assert state2 == state1

    assert_receive {:"$gen_call", _, {:flash_firmware, "none"}}
  end

  test ":best_effort_bug_fix - OK" do
    Helpers.expect_log("Farmduino OK")

    state1 = %UARTCore{rx_count: 100}

    expect(BotState, :fetch, 1, fn ->
      %{informational_settings: %{firmware_version: "1.1.1"}}
    end)

    {:noreply, state2} = UARTCore.handle_info(:best_effort_bug_fix, state1)
    assert state2 == state1
  end

  test ":reset_state" do
    state = %UARTCore{uart_path: "null"}

    expect(BotState, :firmware_offline, 1, fn -> :ok end)

    expect(Support, :connect, 1, fn path ->
      assert path == "null"
      {:ok, self()}
    end)

    expect(Support, :disconnect, 1, fn state1, msg ->
      assert msg == "Rebooting firmware"
      assert state1 == state
      :ok
    end)

    t = fn ->
      {:noreply, result} = UARTCore.handle_info(:reset_state, state)
      assert result.uart_pid == self()
    end

    assert capture_log(t) =~ "Firmware restart initiated"
  end

  test "toggle_logging" do
    UARTCore.toggle_logging(self())
    assert_receive :toggle_logging
    state1 = %UARTCore{logs_enabled: false}
    {:noreply, state2} = UARTCore.handle_info(:toggle_logging, state1)
    refute state1.logs_enabled
    assert state2.logs_enabled
  end

  test "refresh_config" do
    fake_keys = [
      :movement_home_up_z,
      :movement_step_per_mm_x,
      :movement_invert_motor_y,
      :param_e_stop_on_mov_err,
      :encoder_enabled_z
    ]

    UARTCore.refresh_config(self(), fake_keys)
    assert_receive {:refresh_config, ^fake_keys}
    state1 = %UARTCore{}

    expect(ConfigUploader, :refresh, 1, fn state, new_keys ->
      assert new_keys == fake_keys
      assert state == state1
      state
    end)

    {:noreply, state2} =
      UARTCore.handle_info({:refresh_config, fake_keys}, state1)

    assert state2 == state1
  end

  test "flash_firmware" do
    fake_pkg = "express_k10"
    spawn(UARTCore, :flash_firmware, [self(), fake_pkg])
    assert_receive {:"$gen_call", {_, _}, {:flash_firmware, "express_k10"}}, 800
    state1 = %UARTCore{}

    expect(FarmbotOS.Firmware.Flash, :run, 1, fn state, package ->
      assert state == state1
      assert package == fake_pkg
      state
    end)

    {:reply, :ok, state2} =
      UARTCore.handle_call({:flash_firmware, fake_pkg}, self(), state1)

    assert state2 == state1
    assert_receive :reset_state, 800
  end

  test "flash_firmware (nil)" do
    Helpers.expect_log("Can't flash firmware yet because hardware is unknown.")

    {:reply, :ok, state} =
      UARTCore.handle_call({:flash_firmware, nil}, nil, %UARTCore{})

    assert state == %UARTCore{}
  end

  test "start_job" do
    gcode = "E"
    spawn(UARTCore, :start_job, [self(), gcode])
    assert_receive {:"$gen_call", {_, _}, {:start_job, "E"}}, 800
    state1 = %UARTCore{}

    expect(Support, :locked?, 1, fn ->
      true
    end)

    {:reply, {:error, "Device is locked."}, state2} =
      UARTCore.handle_call({:start_job, gcode}, self(), state1)

    assert state2 == state1
  end

  test "terminate" do
    t = fn -> UARTCore.terminate("", "") end
    expect(BotState, :firmware_offline, 1, fn -> nil end)
    assert capture_log(t) =~ "Firmware terminated."
  end

  test "handle_info({:send_raw, _},  state)" do
    fake_gcode = "G00 X1.0 Y2.0 Z3.0 Q0"
    s1 = %UARTCore{}

    expect(Support, :uart_send, 1, fn _uart_pid, msg ->
      assert msg == fake_gcode
      :ok
    end)

    {:noreply, s2} = UARTCore.handle_info({:send_raw, fake_gcode}, s1)
    assert s1 == s2
  end

  test "handle_info({:send_raw, E}, %State{} = state)" do
    expect(Support, :uart_send, 1, fn _uart_pid, msg ->
      assert msg == "E"
      :ok
    end)

    expect(FarmbotOS.Firmware.TxBuffer, :error_all, 1, fn buffer, msg ->
      assert msg == "Emergency locked"
      buffer
    end)

    expect(Support, :lock!, 1, fn -> :ok end)

    s1 = %UARTCore{}
    {:noreply, s2} = UARTCore.handle_info({:send_raw, "E"}, s1)
    assert s1 == s2
  end
end
