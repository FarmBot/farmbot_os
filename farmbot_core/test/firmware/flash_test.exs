defmodule FarmbotCore.Firmware.FlashTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotCore.Firmware.Avrdude
  alias FarmbotCore.Firmware.Flash
  alias FarmbotCore.Firmware.Resetter
  alias FarmbotCore.Firmware.UARTCoreSupport

  setup :verify_on_exit!

  test "Flash.run/2" do
    File.write!("/tmp/fake.hex", "12345")
    real_state = %FarmbotCore.Firmware.UARTCore{uart_path: "ttyACM0"}
    real_package = "arduino"

    expect(Resetter, :find_reset_fun, 1, fn package ->
      assert real_package == package
      {:ok, fn -> "test pass" end}
    end)

    expect(FarmbotCore.Firmware.FlashUtils, :find_hex_file, 1, fn package ->
      assert real_package == package
      {:ok, "/tmp/fake.hex"}
    end)

    expect(UARTCoreSupport, :disconnect, 1, fn state, reason ->
      assert state == real_state
      assert reason == "Starting firmware flash."
      {:ok, :fake_uart_pid}
    end)

    expect(FarmbotCore.BotState, :set_firmware_hardware, 1, fn package ->
      assert real_package == package
    end)

    expect(FarmbotCore.Firmware.UARTCore, :restart_firmware, 1, fn ->
      :ok
    end)

    expect(Avrdude, :flash, fn hex_file, tty, fun ->
      assert hex_file == "/tmp/fake.hex"
      assert tty == :fake_uart_pid
      assert fun.() == "test pass"
      {"", 0}
    end)

    Flash.run(real_state, real_package)
  end
end
