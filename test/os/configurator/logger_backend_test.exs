defmodule FarmbotOS.Configurator.LoggerBackendTest do
  use ExUnit.Case
  # use Mimic
  alias FarmbotOS.Configurator.LoggerBackend, as: LB
  # setup :verify_on_exit!

  @fake_state %{fake: :state}

  test "handle_event - unknown event" do
    assert {:ok, @fake_state} == LB.handle_event(:foo, @fake_state)
  end

  test "handle_call - unknown call" do
    assert {:ok, :ok, @fake_state} == LB.handle_call(:foo, @fake_state)
  end

  test "terminate", do: assert(:ok == LB.terminate(:foo, @fake_state))

  test "handle_call - unknown message" do
    assert {:ok, @fake_state} == LB.handle_info(:foo, @fake_state)
  end
end
