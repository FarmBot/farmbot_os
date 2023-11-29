defmodule FarmbotOS.TerminalHandlerSupportTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.MQTT.TerminalHandlerSupport, as: S
  alias FarmbotOS.MQTT.TerminalHandler, as: T

  test "shell_opts" do
    actual = S.shell_opts()
    expected = [[dot_iex_path: ""]]
    assert actual == expected
  end

  test "tty_send" do
    state = %T{username: "device_456", client_id: "wow"}
    data = "~ EXAMPLE DATA ~"

    expect(FarmbotOS.MQTT, :publish, 1, fn client_id, topic, actual_data ->
      assert topic == "bot/device_456/terminal_output"
      assert client_id == state.client_id
      assert actual_data == data
    end)

    S.tty_send(state, data)
  end

  test "stop_iex - no process" do
    fake_state = %{iex_pid: nil, foo: :bar}
    assert S.stop_iex(fake_state) == fake_state
  end

  test "ExTTY PID lifecycle" do
    if Process.whereis(:ex_tty_handler_farmbot) do
      raise "THIS TEST ASSUMES `:ex_tty_handler_farmbot` NOT RUNNING"
    end

    # === TEST CASE I: Not running

    expect(ExTTY, :start_link, 1, fn opts ->
      assert opts == [
               type: :elixir,
               shell_opts: [[dot_iex_path: ""]],
               handler: self(),
               name: :ex_tty_handler_farmbot
             ]

      {:ok, self()}
    end)

    expect(ExTTY, :window_change, 1, fn pid, width, _height ->
      assert pid == self()
      assert width > 83

      {:ok, self()}
    end)

    state = %T{}
    result = S.start_iex(state)
    assert result == %T{iex_pid: self()}

    {:ok, fake_ex_tty} = NoOp.start_link(name: :ex_tty_handler_farmbot)

    unless Process.whereis(:ex_tty_handler_farmbot) do
      raise "Expected `:ex_tty_handler_farmbot` TO BE RUNNING"
    end

    result = S.start_iex(state)
    expected_state = %T{iex_pid: fake_ex_tty}
    assert result == expected_state

    final_state = S.stop_iex(expected_state)
    assert final_state == %T{iex_pid: nil}
  end
end
