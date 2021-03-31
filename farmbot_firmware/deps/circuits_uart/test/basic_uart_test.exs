Code.require_file("uart_test.exs", __DIR__)

defmodule BasicUARTTest do
  use ExUnit.Case
  alias Circuits.UART

  setup do
    UARTTest.common_setup()
  end

  defp test_send_and_receive(uart1, uart2, options) do
    all_options = [{:active, false} | options]

    assert :ok = UART.open(uart1, UARTTest.port1(), all_options)
    assert :ok = UART.open(uart2, UARTTest.port2(), all_options)

    # uart1 -> uart2
    assert :ok = UART.write(uart1, "A")
    assert {:ok, "A"} = UART.read(uart2)

    # uart2 -> uart1
    assert :ok = UART.write(uart2, "B")
    assert {:ok, "B"} = UART.read(uart1)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "serial ports exist" do
    ports = UART.enumerate()
    assert is_map(ports)
    assert Map.has_key?(ports, UARTTest.port1()), "Can't find #{UARTTest.port1()}"
    assert Map.has_key?(ports, UARTTest.port2()), "Can't find #{UARTTest.port2()}"
  end

  test "simple open and close", %{uart1: uart1} do
    assert :ok = UART.open(uart1, UARTTest.port1(), speed: 9600)
    assert :ok = UART.close(uart1)

    assert :ok = UART.open(uart1, UARTTest.port2())
    assert :ok = UART.close(uart1)

    UART.close(uart1)
  end

  test "open same port twice", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1())
    assert {:error, _} = UART.open(uart2, UARTTest.port1())

    UART.close(uart1)
  end

  test "write and read", %{uart1: uart1, uart2: uart2} do
    test_send_and_receive(uart1, uart2, [])
  end

  test "write iodata", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    assert :ok = UART.write(uart1, 'B')
    assert {:ok, "B"} = UART.read(uart2)

    assert :ok = UART.write(uart1, ['AB', ?C, 'D', "EFG"])

    # Wait for everything to be received in one call
    :timer.sleep(100)
    assert {:ok, "ABCDEFG"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "no cr and lf translations", %{uart1: uart1, uart2: uart2} do
    # It is very common for CR and NL characters to
    # be translated through ttys and serial ports, so
    # check this explicitly.
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    assert :ok = UART.write(uart1, "\n")
    assert {:ok, "\n"} = UART.read(uart2)

    assert :ok = UART.write(uart1, "\r")
    assert {:ok, "\r"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "all characters pass unharmed", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    # The default is 8-N-1, so this should all work
    for char <- 0..255 do
      assert :ok = UART.write(uart1, <<char>>)
      assert {:ok, <<^char>>} = UART.read(uart2)
    end

    UART.close(uart1)
    UART.close(uart2)
  end

  test "send and flush", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    assert :ok = UART.write(uart1, "a")
    :timer.sleep(100)

    assert :ok = UART.flush(uart2, :receive)
    assert {:ok, ""} = UART.read(uart2, 0)

    assert :ok = UART.write(uart1, "b")
    :timer.sleep(100)

    assert :ok = UART.flush(uart2, :both)
    assert {:ok, ""} = UART.read(uart2, 0)

    assert :ok = UART.write(uart1, "c")
    :timer.sleep(100)

    # unspecifed direction should be :both
    assert :ok = UART.flush(uart2)
    assert {:ok, ""} = UART.read(uart2, 0)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "send more than can be done synchronously", %{uart1: uart1, uart2: uart2} do
    # Note: When using the tty0tty driver, both endpoints need to be
    #       opened or writes will fail with :einval. This is different
    #       than most regular uarts where writes to nothing just twiddle
    #       output bits.
    assert :ok = UART.open(uart1, UARTTest.port1())
    assert :ok = UART.open(uart2, UARTTest.port2())

    # Try a big size to trigger a write that can't complete
    # immediately. This doesn't always work.
    lots_o_data = :binary.copy("a", 5000)

    # Allow 10 seconds for write to give it time to complete
    assert :ok = UART.write(uart1, lots_o_data, 10000)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "send timeout", %{uart1: uart1} do
    # Don't run against tty0tty since it sends data almost
    # instantaneously. Also, Windows appears to have a deep
    # send buffer. Need to investigate the Windows failure more.
    if !String.starts_with?(UARTTest.port1(), "tnt") && !:os.type() == {:windows, :nt} do
      assert :ok = UART.open(uart1, UARTTest.port1(), speed: 1200)

      # Send more than can be sent on a 1200 baud link
      # in 10 milliseconds
      lots_o_data = :binary.copy("a", 5000)
      assert {:error, :eagain} = UART.write(uart1, lots_o_data, 10)

      UART.close(uart1)
    end
  end

  test "sends coalesce into one read", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    assert :ok = UART.write(uart1, "a")
    assert :ok = UART.write(uart1, "b")
    assert :ok = UART.write(uart1, "c")

    :timer.sleep(100)

    assert {:ok, "abc"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "error writing to a closed port", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    # port1 not yet opened
    assert {:error, :ebadf} = UART.write(uart1, "A")

    # port1 opened
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.write(uart1, "A")
    assert {:ok, "A"} = UART.read(uart2)

    # port1 closed
    assert :ok = UART.close(uart1)
    assert {:error, :ebadf} = UART.write(uart1, "B")

    UART.close(uart1)
    UART.close(uart2)
  end

  test "open doesn't return error AND send a message when in active mode", %{
    uart1: uart1
  } do
    :ok = UART.configure(uart1, active: true)
    {:error, _} = UART.open(uart1, "does_not_exist")
    refute_received {:circuits_uart, _port, _}, "No messages should be sent if open returns error"

    :ok = UART.configure(uart1, active: false)
    {:error, _} = UART.open(uart1, "does_not_exist", active: true)
    refute_received {:circuits_uart, _port, _}, "No messages should be sent if open returns error"
  end

  test "open doesn't send messages in passive mode for open errors", %{
    uart1: uart1
  } do
    :ok = UART.configure(uart1, active: false)
    {:error, :enoent} = UART.open(uart1, "does_not_exist")
    refute_received {:circuits_uart, _, _}, "No messages should be sent in passive mode"

    {:error, :enoent} = UART.open(uart1, "does_not_exist", active: false)
    refute_received {:circuits_uart, _, _}, "No messages should be sent in passive mode"
  end

  test "error writing to a closed port when using framing", %{uart1: uart1, uart2: uart2} do
    framing = {UART.Framing.Line, separator: "\n"}
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false, framing: framing)

    # port1 not yet opened
    assert {:error, :ebadf} = UART.write(uart1, "A")

    # port1 opened
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false, framing: framing)
    assert :ok = UART.write(uart1, "A")
    assert {:ok, "A"} = UART.read(uart2)

    # port1 closed
    assert :ok = UART.close(uart1)
    assert {:error, :ebadf} = UART.write(uart1, "B")

    UART.close(uart1)
    UART.close(uart2)
  end

  test "active mode receive", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: true)
    port2 = UARTTest.port2()

    # First write
    assert :ok = UART.write(uart1, "a")
    assert_receive {:circuits_uart, ^port2, "a"}

    # Only one message should be sent
    refute_receive {:circuits_uart, _, _}

    # Try another write
    assert :ok = UART.write(uart1, "b")
    assert_receive {:circuits_uart, ^port2, "b"}

    UART.close(uart1)
    UART.close(uart2)
  end

  test "active mode receive with id: :pid", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: true, id: :pid)
    port2 = UARTTest.port2()

    # First write
    assert :ok = UART.write(uart1, "a")
    assert_receive {:circuits_uart, ^uart2, "a"}

    # Only one message should be sent
    refute_receive {:circuits_uart, _, _}

    # Configure to id: :name
    UART.configure(uart2, id: :name)

    # Try another write
    assert :ok = UART.write(uart1, "b")
    assert_receive {:circuits_uart, ^port2, "b"}

    # Configure to id: :pid
    UART.configure(uart2, id: :pid)

    # Try another write
    assert :ok = UART.write(uart1, "c")
    assert_receive {:circuits_uart, ^uart2, "c"}

    UART.close(uart1)
    UART.close(uart2)
  end

  test "error when calling read in active mode", %{uart1: uart1} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: true)
    assert {:error, :einval} = UART.read(uart1)
    UART.close(uart1)
  end

  test "active mode on then off", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)
    port2 = UARTTest.port2()

    assert :ok = UART.write(uart1, "a")
    assert {:ok, "a"} = UART.read(uart2, 100)

    assert :ok = UART.configure(uart2, active: true)
    assert :ok = UART.write(uart1, "b")
    assert_receive {:circuits_uart, ^port2, "b"}

    assert :ok = UART.configure(uart2, active: false)
    assert :ok = UART.write(uart1, "c")
    assert {:ok, "c"} = UART.read(uart2, 100)
    refute_receive {:circuits_uart, _, _}

    assert :ok = UART.configure(uart2, active: true)
    assert :ok = UART.write(uart1, "d")
    assert_receive {:circuits_uart, ^port2, "d"}

    refute_receive {:circuits_uart, _, _}

    UART.close(uart1)
    UART.close(uart2)
  end

  test "active mode gets event when write fails", %{uart1: uart1} do
    # This only works with tty0tty since it fails write operations if no
    # receiver.

    if String.starts_with?(UARTTest.port1(), "tnt") do
      assert :ok = UART.open(uart1, UARTTest.port1(), active: true)
      port1 = UARTTest.port1()

      assert {:error, :einval} = UART.write(uart1, "a")
      assert_receive {:circuits_uart, ^port1, {:error, :einval}}

      UART.close(uart1)
    end
  end

  test "read timeout works", %{uart1: uart1} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)

    # 0 duration timeout
    start = System.monotonic_time(:millisecond)
    assert {:ok, <<>>} = UART.read(uart1, 0)
    elapsed_time = System.monotonic_time(:millisecond) - start
    assert_in_delta elapsed_time, 0, 100

    # 500 ms timeout
    start = System.monotonic_time(:millisecond)
    assert {:ok, <<>>} = UART.read(uart1, 500)
    elapsed_time = System.monotonic_time(:millisecond) - start
    assert_in_delta elapsed_time, 400, 600

    UART.close(uart1)
  end

  test "opened uart returns the configuration", %{uart1: uart1} do
    :ok = UART.open(uart1, UARTTest.port1(), active: false, speed: 57_600)
    {name, opts} = UART.configuration(uart1)
    assert name == UARTTest.port1()
    assert Keyword.get(opts, :active) == false
    assert Keyword.get(opts, :speed) == 57_600
    UART.close(uart1)
  end

  test "reconfiguring the uart updates the configuration", %{uart1: uart1} do
    :ok = UART.open(uart1, UARTTest.port1(), active: false, speed: 9600)
    {name, opts} = UART.configuration(uart1)
    assert name == UARTTest.port1()
    assert Keyword.get(opts, :active) == false
    assert Keyword.get(opts, :speed) == 9600

    :ok = UART.configure(uart1, active: true, speed: 115_200)
    {name, opts} = UART.configuration(uart1)
    assert name == UARTTest.port1()
    assert Keyword.get(opts, :active) == true
    assert Keyword.get(opts, :speed) == 115_200

    UART.close(uart1)
  end

  # Software flow control doesn't work and I'm not sure what the deal is
  if false do
    test "xoff filtered with software flow control", %{uart1: uart1, uart2: uart2} do
      if !String.starts_with?(UARTTest.port1(), "tnt") do
        assert :ok = UART.open(uart1, UARTTest.port1(), flow_control: :softare, active: false)
        assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

        # Test that uart1 filters xoff
        assert :ok = UART.write(uart2, @xoff)
        assert {:ok, ""} = UART.read(uart1, 100)

        # Test that uart1 filters xon
        assert :ok = UART.write(uart2, @xon)
        assert {:ok, ""} = UART.read(uart1, 100)

        # Test that uart1 doesn't filter other things
        assert :ok = UART.write(uart2, "Z")
        assert {:ok, "Z"} = UART.read(uart1, 100)

        UART.close(uart1)
        UART.close(uart2)
      end
    end

    test "software flow control pausing", %{uart1: uart1, uart2: uart2} do
      if !String.starts_with?(UARTTest.port1(), "tnt") do
        assert :ok = UART.open(uart1, UARTTest.port1(), flow_control: :softare, active: false)
        assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

        # send XOFF to uart1 so that it doesn't transmit
        assert :ok = UART.write(uart2, @xoff)
        assert :ok = UART.write(uart1, "a")
        assert {:ok, ""} = UART.read(uart2, 100)

        # send XON to see if we get the "a"
        assert :ok = UART.write(uart2, @xon)
        assert {:ok, "a"} = UART.read(uart2, 100)

        UART.close(uart1)
        UART.close(uart2)
      end
    end
  end

  test "call controlling_process", %{uart1: uart1} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false)
    assert :ok = UART.controlling_process(uart1, self())
    UART.close(uart1)
  end

  test "changing config on open port" do
    # Implement me.
  end

  test "opening port with custom speed", %{uart1: uart1} do
    assert :ok = UART.open(uart1, UARTTest.port1(), active: false, speed: 192_000)
    UART.close(uart1)
  end

  test "write and read at standard speeds", %{uart1: uart1, uart2: uart2} do
    standard_speeds = [9600, 19200, 38400, 57600, 115_200]

    for speed <- standard_speeds do
      test_send_and_receive(uart1, uart2, speed: speed)
    end
  end

  test "write and read at custom speeds", %{uart1: uart1, uart2: uart2} do
    # 31250 - MIDI
    # 64000, 192_000, 200_000 - Random speeds seen in the field
    #
    # NOTE: This test is highly dependent on the UARTs under test being able
    #       to support these baud rates, so it may not be a Circuits.UART
    #       issue if it fails.
    custom_speeds = [31250, 64000, 192_000, 200_000]

    for speed <- custom_speeds do
      test_send_and_receive(uart1, uart2, speed: speed)
    end
  end
end
