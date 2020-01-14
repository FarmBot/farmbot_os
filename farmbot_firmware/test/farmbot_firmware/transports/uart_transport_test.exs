Mox.defmock(FarmbotFirmware.UartTestAdapter, for: FarmbotFirmware.UartAdapter)

defmodule FarmbotFirmware.UARTTransportTest do
  use ExUnit.Case
  import Mox
  setup [:verify_on_exit!]
  doctest FarmbotFirmware.UARTTransport
  alias FarmbotFirmware.{UartTestAdapter, UARTTransport}

  test "UARTTransport.init/1" do
    expect(UartTestAdapter, :start_link, fn ->
      {:ok, :FAKE_UART}
    end)

    init_args = [
      device: :FAKE_DEVICE,
      handle_gcode: :FAKE_GCODE_HANDLER,
      reset: :FAKE_RESETER
    ]

    {:ok, state, 0} = UARTTransport.init(init_args)
    assert state.device == Keyword.fetch!(init_args, :device)
    assert state.handle_gcode == Keyword.fetch!(init_args, :handle_gcode)
    assert state.reset == Keyword.fetch!(init_args, :reset)
  end

  test "UARTTransport.terminate/2" do
    expect(UartTestAdapter, :stop, fn uart ->
      assert uart == :whatever
    end)

    state = %{uart: :whatever}
    UARTTransport.terminate(nil, state)
  end

  test "UARTTransport resets UART on timeout" do
    state = %{uart: :FAKE_UART, device: :FAKE_DEVICE, open: false}

    fake_opts = [fake_opts: true]

    expect(UartTestAdapter, :generate_opts, fn ->
      fake_opts
    end)

    expect(UartTestAdapter, :open, fn uart, dev, opts ->
      assert uart == state.uart
      assert dev == state.device
      assert fake_opts == opts
      :ok
    end)

    {:noreply, state2} = UARTTransport.handle_info(:timeout, state)
    # Expect the `open` state to toggle back to "true" from "false":
    refute state.open == state2.open
  end

  test "UARTTransport handles unexpected UART errors" do
    state = %{uart: :FAKE_UART, device: :FAKE_DEVICE, open: false}

    fake_opts = [fake_opts: true]

    expect(UartTestAdapter, :generate_opts, fn ->
      fake_opts
    end)

    expect(UartTestAdapter, :open, fn _, _, _ ->
      {:error, "Simulated UART failure. This is OK"}
    end)

    {:noreply, state2, retry_timeout} = UARTTransport.handle_info(:timeout, state)
    assert retry_timeout == 5000
    assert state.open == state2.open
  end

  test "UARTTransport.reset/2" do
    empty_state = %{reset: nil}
    ok_state = %{reset: %{reset: :fake_reset}}
    assert :ok == UARTTransport.reset(empty_state)
    assert :fake_reset == UARTTransport.reset(ok_state)
  end

  test "UARTTransport.open/2" do
    me = self()

    expect(UartTestAdapter, :open, fn pid, path, opts ->
      assert pid == me
      assert path == "/dev/null"
      assert opts == [a: :b]
    end)

    UARTTransport.open(me, "/dev/null", a: :b)
  end
end
