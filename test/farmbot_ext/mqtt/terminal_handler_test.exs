defmodule FarmbotOS.TerminalHandlerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.MQTT.{
    TerminalHandler,
    TerminalHandlerSupport
  }

  test "handle_info - unknown messages" do
    expect(TerminalHandlerSupport, :tty_send, 1, fn state, message ->
      assert message == "UNKNOWN TERMINAL MSG - :unknown_msg"
      assert state == :misc_state
    end)

    reply = TerminalHandler.handle_info(:unknown_msg, :misc_state)
    assert reply == {:noreply, :misc_state}
  end

  test "handle_info - activity timeout" do
    fake_state = %TerminalHandler{
      iex_pid: self()
    }

    expect(TerminalHandlerSupport, :tty_send, 1, fn state, message ->
      assert message == "=== Session inactivity timeout ==="
      assert state == fake_state
    end)

    expect(TerminalHandlerSupport, :stop_iex, 1, fn state ->
      assert state == fake_state
      :whatever_stop_iex_returns
    end)

    reply = TerminalHandler.handle_info(:timeout, fake_state)
    assert reply == {:noreply, :whatever_stop_iex_returns}
  end

  test "handle_info({:tty_data, data}, state) - TTY => MQTT" do
    expect(TerminalHandlerSupport, :tty_send, 1, fn state, message ->
      assert message == "echo hi"
      assert state == :misc_state
    end)

    reply = TerminalHandler.handle_info({:tty_data, "echo hi"}, :misc_state)
    assert reply == {:noreply, :misc_state, 300_000}
  end

  test "handle_info({:inbound, _, _}, state) - IEX Session active" do
    state = %TerminalHandler{iex_pid: self()}

    expect(ExTTY, :send_text, 1, fn pid, message ->
      assert pid == self()
      assert message == "echo hi"
    end)

    reply = TerminalHandler.handle_info({:inbound, "...", "echo hi"}, state)
    assert reply == {:noreply, state, 300_000}
  end

  test "handle_info - IEX Session NOT active" do
    state = %TerminalHandler{iex_pid: nil}

    expect(TerminalHandlerSupport, :start_iex, 1, fn old_state ->
      assert old_state == state
      %{state | iex_pid: self()}
    end)

    expect(TerminalHandlerSupport, :tty_send, 1, fn new_state, message ->
      assert message == "Starting IEx..."
      refute new_state.iex_pid
    end)

    msg = {:inbound, "?", "ls"}
    {:noreply, new_state} = reply = TerminalHandler.handle_info(msg, state)
    assert new_state.iex_pid
    assert reply == {:noreply, new_state}
  end
end
