defmodule FarmbotFirmware.RequestTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.Request

  test "request whitelist" do
    boom = fn ->
      Request.request({:a, {:b, :c}})
    end

    assert_raise ArgumentError, boom
  end
end
