defmodule RSATest do
  require Helpers
  use ExUnit.Case

  def priv_key(), do: RSA.decode_key(Helpers.priv_key())
  def pub_key(), do: RSA.decode_key(Helpers.pub_key())

  test "decode_key" do
    {:RSAPublicKey, huge_integer, small_integer} = pub_key()
    assert huge_integer > 999_999_999_999
    assert small_integer == 65537
  end

  test "encryption" do
    ct = RSA.encrypt("TOP SECRET", {:public, pub_key()})
    pt = :public_key.decrypt_private(ct, priv_key())

    assert pt == "TOP SECRET"
  end
end
