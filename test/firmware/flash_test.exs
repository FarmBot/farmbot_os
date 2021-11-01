defmodule FarmbotOS.Firmware.FlashTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Firmware.Avrdude
  alias FarmbotOS.Firmware.Flash
  alias FarmbotOS.Firmware.Resetter
  alias FarmbotOS.Firmware.UARTCoreSupport

  setup :verify_on_exit!

  test "Flash.run/2" do
    File.write!("/tmp/fake.hex", "12345")
    real_state = %FarmbotOS.Firmware.UARTCore{uart_path: "ttyACM0"}
    real_package = "arduino"

    expect(Resetter, :find_reset_fun, 1, fn package ->
      assert real_package == package
      {:ok, fn -> "test pass" end}
    end)

    expect(FarmbotOS.Firmware.FlashUtils, :find_hex_file, 1, fn package ->
      assert real_package == package
      {:ok, "/tmp/fake.hex"}
    end)

    expect(UARTCoreSupport, :disconnect, 1, fn state, reason ->
      assert state == real_state
      assert reason == "Starting firmware flash."
      {:ok, :fake_uart_pid}
    end)

    expect(FarmbotOS.BotState, :set_firmware_hardware, 1, fn package ->
      assert real_package == package
    end)

    expect(FarmbotOS.Firmware.UARTCore, :restart_firmware, 1, fn ->
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
