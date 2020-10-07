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
end
