defmodule Farmbot.Serial.HandlerTest do
  use ExUnit.Case, async: false
  alias Farmbot.Serial.Handler
  alias Farmbot.CeleryScript.{Command, Ast}

  setup_all do
    :ok = wait_for_serial_available()
    :ok
  end

  test "checks serial availablity" do
    bool = Handler.available?
    assert bool == true
  end

  test "gets the state" do
    state = Handler.get_state
    assert is_pid(state.nerves)
    assert state.tty == "/dev/tnt1"
  end

  def wait_for_serial_available(count \\ 0)

  def wait_for_serial_available(count) when count > 1000 do
    flunk "this probably isnt going to fix itself"
    {:error, :timeout}
  end

  def wait_for_serial_available(count) do
    case Process.whereis(Handler) do
      nil ->
        Process.sleep(10)
        wait_for_serial_available(count + 1)
      _ ->
        unless Handler.available? do
          Process.sleep(10)
          wait_for_serial_available(count + 1)
        end
        Command.home(%{axis: "all"}, [], Ast.Context.new())
        Process.sleep(10)
        :ok
    end
  end
end
