defmodule FarmbotCore.Firmware.UARTObserverTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.FirmwareConfig
  alias FarmbotCore.Firmware.UARTCore
  alias FarmbotCore.Firmware.UARTObserver

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

    expect(FarmbotCore.BotState, :fetch, 1, fn ->
      %{mcu_params: %{movement_axis_nr_steps_z: 100.0}}
    end)

    expect(FarmbotCore.Asset, :firmware_config, 1, fn ->
      %{movement_axis_nr_steps_z: 200.0}
    end)

    state = %UARTCore{uart_pid: self()}
    results = UARTObserver.handle_info({:data_available, FirmwareConfig}, state)
    assert {:noreply, state} == results
  end
end
