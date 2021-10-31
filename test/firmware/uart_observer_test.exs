defmodule FarmbotOS.Firmware.UARTObserverTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.AssetWorker.FarmbotOS.Asset.FirmwareConfig
  alias FarmbotOS.Firmware.UARTCore
  alias FarmbotOS.Firmware.UARTObserver

  test "data_available/2" do
    parent_pid = self()

    caller = fn ->
      UARTObserver.data_available(parent_pid, FirmwareConfig)
    end

    spawn_link(caller)
    assert_receive {:data_available, FirmwareConfig}, 888
  end

  test "unknown messages" do
    {:ok, pid} = UARTObserver.start_link([], [])
    send(pid, :unknown_message)
    Process.sleep(1000)
    assert Process.alive?(pid)
  end

  test "{:data_available, FirmwareConfig}" do
    me = self()

    expect(UARTCore, :refresh_config, 1, fn pid, keys ->
      assert pid == me
      assert keys == [:movement_axis_nr_steps_z]
      :ok
    end)

    expect(FarmbotOS.BotState, :fetch, 1, fn ->
      %{mcu_params: %{movement_axis_nr_steps_z: 100.0}}
    end)

    expect(FarmbotOS.Asset, :firmware_config, 1, fn ->
      %{movement_axis_nr_steps_z: 200.0}
    end)

    state = %UARTCore{uart_pid: self()}
    results = UARTObserver.handle_info({:data_available, FirmwareConfig}, state)
    assert {:noreply, state} == results
  end

  test ":connect_uart" do
    me = self()

    expect(FarmbotOS.Firmware.UARTCore, :start_link, 1, fn opts ->
      assert opts == [path: "path", fw_type: "package"]
      {:ok, me}
    end)

    expect(FarmbotOS.Firmware.UARTDetector, :run, 1, fn ->
      {"package", "path"}
    end)

    expect(FarmbotOS.Firmware.UARTCoreSupport, :recent_boot?, 1, fn ->
      false
    end)

    {:noreply, state2} =
      UARTObserver.handle_info(:connect_uart, %{uart_pid: nil})

    assert state2.uart_pid == me
  end
end
