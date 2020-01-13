Mox.defmock(FarmbotFirmware.UartTestAdapter, for: FarmbotFirmware.UartAdapter)

defmodule FarmbotFirmware.UARTTransportTest do
  use ExUnit.Case
  import Mox
  setup [:verify_on_exit!]
  doctest FarmbotFirmware.UARTTransport

  test "FarmbotFirmware.UARTTransport.open/2" do
    me = self()

    expect(FarmbotFirmware.UartTestAdapter, :open, fn pid, path, opts ->
      assert pid == me
      assert path == "/dev/null"
      assert opts == [a: :b]
    end)

    FarmbotFirmware.UARTTransport.open(me, "/dev/null", a: :b)
  end

  defmodule FakeReseter do
    def reset do
      :fake_reset
    end
  end

  test "FarmbotFirmware.UARTTransport.reset/2" do
    empty_state = %{reset: nil}
    ok_state = %{reset: FakeReseter}
    assert :ok == FarmbotFirmware.UARTTransport.reset(empty_state)
    assert :fake_reset == FarmbotFirmware.UARTTransport.reset(ok_state)
  end
end
