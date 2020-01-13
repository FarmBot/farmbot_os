Mox.defmock(FarmbotFirmware.UartTestAdapter, for: FarmbotFirmware.UartAdapter)

defmodule FarmbotFirmware.UARTTransportTest do
  use ExUnit.Case
  import Mox
  setup [:verify_on_exit!]
  doctest FarmbotFirmware.UARTTransport

  test "FarmbotFirmware.UARTTransport.init/1" do
    expect(FarmbotFirmware.UartTestAdapter, :start_link, fn ->
      {:ok, :FAKE_UART}
    end)

    init_args = [
      device: :FAKE_DEVICE,
      handle_gcode: :FAKE_GCODE_HANDLER,
      reset: :FAKE_RESETER
    ]

    {:ok, state, 0} = FarmbotFirmware.UARTTransport.init(init_args)
    assert state.device == Keyword.fetch!(init_args, :device)
    assert state.handle_gcode == Keyword.fetch!(init_args, :handle_gcode)
    assert state.reset == Keyword.fetch!(init_args, :reset)
  end

  test "FarmbotFirmware.UARTTransport.terminate/2" do
    expect(FarmbotFirmware.UartTestAdapter, :stop, fn uart ->
      assert uart == :whatever
    end)

    state = %{uart: :whatever}
    FarmbotFirmware.UARTTransport.terminate(nil, state)
  end

  test "FarmbotFirmware.UARTTransport.reset/2" do
    empty_state = %{reset: nil}
    ok_state = %{reset: %{reset: :fake_reset}}
    assert :ok == FarmbotFirmware.UARTTransport.reset(empty_state)
    assert :fake_reset == FarmbotFirmware.UARTTransport.reset(ok_state)
  end

  test "FarmbotFirmware.UARTTransport.open/2" do
    me = self()

    expect(FarmbotFirmware.UartTestAdapter, :open, fn pid, path, opts ->
      assert pid == me
      assert path == "/dev/null"
      assert opts == [a: :b]
    end)

    FarmbotFirmware.UARTTransport.open(me, "/dev/null", a: :b)
  end
end
