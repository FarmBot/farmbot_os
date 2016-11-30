defmodule TokenTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a Token" do
    t =
    %{"encoded" => "big crazy long string",
      "unencoded" =>
        %{"bot" => "the most creative name ever",
          "exp" => 123,
          "fw_update_server" => "http://copy_paste.com",
          "os_update_server" => "http://copy_paste.com",
          "iat" => 555,
          "iss" => "connor@farmbot.io",
          "jti" => "big_long_thing",
          "mqtt" => "mqtt.url.com",
          "sub" => "email@something_rediculous.com"}}
    {:ok, not_fail} = Token.create(t)
    # test the shortuct while im here
    {:ok, ^not_fail} = Token.create({:ok, t})
    assert not_fail.encoded == "big crazy long string"
    un = not_fail.unencoded
    assert un.bot == "the most creative name ever"
    assert un.exp == 123
    assert un.iat == 555
    assert un.sub == "email@something_rediculous.com"
    assert un.iss == "connor@farmbot.io"
    assert un.fw_update_server == "http://copy_paste.com"
    assert un.os_update_server == "http://copy_paste.com"
  end

  test "does not build a Token" do
    fail = Token.create(%{"fake" => "Token"})
    also_fail = Token.create(:wrong_type)
    assert(fail == {Token, :malformed})
    assert(also_fail == {Token, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Token} Object", fn ->
      Token.create!(%{"fake" => "Token"})
    end
  end
end
