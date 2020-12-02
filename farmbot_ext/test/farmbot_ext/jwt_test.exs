defmodule FarmbotExt.JWTTest do
  use ExUnit.Case
  alias FarmbotExt.JWT

  test "decode! (error)" do
    boom = fn -> JWT.decode!("{}.{}.{}") end
    assert_raise RuntimeError, "base64_decode_fail", boom
  end
end
