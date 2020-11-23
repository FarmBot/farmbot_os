defmodule FarmbotFirmware.RequestTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.Request

  test "request ok" do
    boom = fn ->
      Request.request({:a, {:b, :c}})
    end

    assert_raise ArgumentError, boom
  end

  test "timeout handler" do
    ok = Request.request_timeout(:tag, :code, :result)
    error = Request.request_timeout(:tag, :code)
    assert {:ok, {:tag, :result}} == ok
    assert {:error, "timeout waiting for request to complete: :code"} == error
  end

  def do_spawn_my_test(caller, code) do
    result = Request.wait_for_request_result(nil, code)
    send(caller, result)
  end

  def spawn_my_test() do
    spawn(__MODULE__, :do_spawn_my_test, [
      self(),
      {nil, {:parameter_read, [:x]}}
    ])
  end

  test "handle errors reported by firmware" do
    pid = spawn_my_test()
    my_error = {:report_error, 4_567_890}
    send(pid, {nil, my_error})
    assert_receive(my_error, 500, "Expected firmware errors to be echoed")
  end
end
