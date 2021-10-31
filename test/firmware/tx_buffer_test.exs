defmodule FarmbotOS.Firmware.TxBufferTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotOS.Firmware.TxBuffer
  alias FarmbotOS.Firmware.GCode
  alias FarmbotOS.Firmware.UARTCoreSupport, as: Support
  doctest FarmbotOS.Firmware.TxBuffer, import: true

  @fake_buffer1 TxBuffer.new()
                |> TxBuffer.push(nil, GCode.new(:A, []))
                |> TxBuffer.push(nil, GCode.new(:B, []))
                |> TxBuffer.push(nil, GCode.new(:C, []))
                |> TxBuffer.push(nil, GCode.new(:D, []))
                |> TxBuffer.push(nil, GCode.new(:E, []))

  @busy_buffer %TxBuffer{
    autoinc: 0,
    current: %{
      id: 1,
      caller: :fake_caller,
      gcode: GCode.new(:E, []),
      echo: nil
    },
    queue: []
  }

  @ready_buffer %TxBuffer{
    autoinc: 0,
    current: nil,
    queue: [
      %{
        id: 1,
        caller: :this_is_a_fake_caller,
        gcode: GCode.new(:E, []),
        echo: nil
      }
    ]
  }

  test "error_all/2 drains queue" do
    next_state = TxBuffer.error_all(@fake_buffer1, "Running unit tests")
    assert next_state

    assert next_state == TxBuffer.new()
  end

  test "process_next_message - Empty queue" do
    new = TxBuffer.new()
    result = TxBuffer.process_next_message(new, self())
    assert result == new
  end

  test "process_next_message - Waiting for response" do
    result = TxBuffer.process_next_message(@busy_buffer, self())
    assert result == @busy_buffer
  end

  test "process_next_message - Corner case I" do
    parent_pid = self()
    caller = fn -> TxBuffer.process_next_message(@ready_buffer, parent_pid) end
    spawn_link(caller)
    assert_receive {:"$gen_call", {_, _}, {:write, "E Q1", 5000}}, 888
  end

  test "process_next_message - Corner case II" do
    expect(Support, :uart_send, 1, fn pid, gcode ->
      assert gcode == "E Q1"
      assert pid == :my_fake_pid
    end)

    expected = %TxBuffer{
      current: %{
        caller: :this_is_a_fake_caller,
        gcode: %GCode{command: :E, echo: nil, params: [], string: "E Q1"},
        id: 1,
        echo: nil
      },
      autoinc: 1,
      queue: []
    }

    actual = TxBuffer.process_next_message(@ready_buffer, :my_fake_pid)
    assert expected == actual
  end

  test "process_ok(state, queue0)" do
    assert TxBuffer.process_ok(@fake_buffer1, 0) == @fake_buffer1
  end

  test "process_ok(state, non_zero_queues)" do
    fake_response = {:ok, nil}

    expect(Support, :reply, 1, fn caller, response ->
      assert caller == @busy_buffer.current.caller
      assert response == fake_response
      :ok
    end)

    result = TxBuffer.process_ok(@busy_buffer, 1)

    expected = %TxBuffer{
      autoinc: @busy_buffer.autoinc,
      current: nil,
      queue: []
    }

    assert result == expected
  end

  test "process_error()" do
    fake_response = {:error, nil}

    expect(Support, :reply, 1, fn caller, response ->
      assert caller == @busy_buffer.current.caller
      assert response == fake_response
      :ok
    end)

    result = TxBuffer.process_error(@busy_buffer, {1, 0})

    expected = %TxBuffer{
      autoinc: @busy_buffer.autoinc,
      current: nil,
      queue: []
    }

    assert result == expected
  end

  test "process_echo() - capture corrupt echo" do
    boom = fn -> TxBuffer.process_echo(@busy_buffer, "Whoops") end
    msg = "CORRUPT ECHO! Expected echo \"Whoops\" to equal \"E\""
    assert_raise RuntimeError, msg, boom
  end

  test "process_echo() - capture well formed echo" do
    job = TxBuffer.process_echo(@busy_buffer, "E").current
    assert job.gcode.echo == job.gcode.string
  end

  test "process_echo() - ignore untracked command echoes" do
    echo = fn -> TxBuffer.process_echo(@ready_buffer, "Whoops") end
    assert capture_log(echo) =~ "Ignoring untracked echo: \"Whoops\""
  end
end
