defmodule FarmbotCore.Firmware.UARTCoreTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotCore.Firmware.UARTCore
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support
  alias FarmbotCore.Firmware.ConfigUploader
  setup :set_mimic_global
  setup :verify_on_exit!
  @path "ttyACM0"

  test "lifecycle" do
    expect(Support, :connect, 1, fn @path -> {:ok, self()} end)
    {:ok, pid} = UARTCore.start_link([path: @path], [])
    assert is_pid(pid)
    noise = fn -> send(pid, "nonsense") end
    expected = "UNEXPECTED FIRMWARE MESSAGE: \"nonsense\""
    Process.sleep(800)
    assert capture_log(noise) =~ expected

    state1 = :sys.get_state(pid)
    refute state1.rx_buffer.ready

    send(pid, {:circuits_uart, "", "r99 "})
    state2 = :sys.get_state(pid)
    refute state2.rx_buffer.ready

    send(pid, {:circuits_uart, "", "ARDUINO startup COMPLETE\r\n"})
    state3 = :sys.get_state(pid)
    assert state3.rx_buffer.ready
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

    expect(FarmbotCore.Firmware.Flash, :run, 1, fn state, package ->
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
    t = fn ->
      {:reply, :ok, state} =
        UARTCore.handle_call({:flash_firmware, nil}, nil, %UARTCore{})

      assert state == %UARTCore{}
    end

    assert capture_log(t) =~
             "Can't flash firmware yet because hardware is unknown."
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
    expect(FarmbotCore.BotState, :firmware_offline, 1, fn -> nil end)
    assert capture_log(t) =~ "Firmware terminated."
  end
end
