defmodule RSATest do
  use ExUnit.Case, async: true

  @pub_key "-----BEGIN PUBLIC KEY-----\n" <>
             "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqi880lw9oeNp60qx5Oow\n" <>
             "9czLrvExJSGO6Yic7G+dvoqea9gLT3Xf0x4Iy4TmUfnFT2cJ1I79o/JS6WmfMVdr\n" <>
             "5Z0TaoVWYe9T01+kv6xWY+hENZTemAyCxSyPD7n6BgQYjXVoKSrdIuAoawtozQG+\n" <>
             "5KrS+KnRI70kVO2hgz1NXiEXuHF2Za4umCBONXBdpBSXVq1G5mpF6JURqu7oaTmE\n" <>
             "QNCmXfsJXE2srVwEshg80sb5rRtuoQAF7lAGZ3khV7DzKear5You9BWYNsl6etJZ\n" <>
             "lOSiNeGsDyUEocSIJ9Mn+y8jphJICbBADoKXO3ZkznnJRtLSE5cuh9KVL99LUWAk\n" <>
             "+wIDAQAB\n" <>
             "-----END PUBLIC KEY-----\n" <>
             ""

  @priv_key "-----BEGIN RSA PRIVATE KEY-----\n" <>
              "MIIEpAIBAAKCAQEAqi880lw9oeNp60qx5Oow9czLrvExJSGO6Yic7G+dvoqea9gL\n" <>
              "T3Xf0x4Iy4TmUfnFT2cJ1I79o/JS6WmfMVdr5Z0TaoVWYe9T01+kv6xWY+hENZTe\n" <>
              "mAyCxSyPD7n6BgQYjXVoKSrdIuAoawtozQG+5KrS+KnRI70kVO2hgz1NXiEXuHF2\n" <>
              "Za4umCBONXBdpBSXVq1G5mpF6JURqu7oaTmEQNCmXfsJXE2srVwEshg80sb5rRtu\n" <>
              "oQAF7lAGZ3khV7DzKear5You9BWYNsl6etJZlOSiNeGsDyUEocSIJ9Mn+y8jphJI\n" <>
              "CbBADoKXO3ZkznnJRtLSE5cuh9KVL99LUWAk+wIDAQABAoIBAFczFQsEUGAe0irJ\n" <>
              "fxU4GhYX9VWSKAhKhZuLcDyFhGIZTMsdS85PK3xVK1R8qDbgsATbWuIa0kOq6mjG\n" <>
              "wdbaYGKqdURjRbuwkVcA7r13ZFyUqj56JQPrhSXaiwMX29AxURNKUTCm0eAI0yzm\n" <>
              "D7DbcCBilu7qtEqHo5IQoG1Kf9X2cFYr7ikY8cx0E90RUTZ+P2RCuWskGEKxbUWJ\n" <>
              "epB2BwvxBAJrCSvt3DoXYWNkuxXo32SepqACyqyFPgWImvlz+5CACwrP8fXAhaut\n" <>
              "QbULN+4ltLnl7JQgKKMrGaKOGxvSwLFge9HyNg8ggdIkIjatxOJXLNNLyNgt6fNL\n" <>
              "FuICNSECgYEA4VRl4P3kFcAAIxdlDm0zm5bzegFTidr9QY9r1akzGIKGmT4uOAKX\n" <>
              "vWxQuR2R7LhYXeDW67BIkeYDZd+PW+eH6oVzb2W4MAggu6FeQgCa+uwnp6En13LE\n" <>
              "AX7NdH37h4SmbK4ssQQbb6S5oCuOzBKCVQCPlIRbEnk7MjluZBJfYnUCgYEAwVlP\n" <>
              "KBNL466T+8gKh5mQCXuV1bGKtYlbT/pnmNlz7gfXVPkj+UaBslOmDthEVbGvL4gY\n" <>
              "4T0vhP4VmIz8VqLw+jcCSezv0DjQVXYzZ8l+mNzHkacnnytM4VLQEYQnPB827Mo1\n" <>
              "FF2SjrfciQSyxxg+HOhHVUPovKvExsLtm8tzm68CgYEAl8o25x2hLFWuwfTcip9d\n" <>
              "iI5jbei+0brHqAZpagEU/onPCiQtFmYIuf3hUxJsXr7AKF1x6ktSV5ZO661x8UNC\n" <>
              "9+T2IjCvpwuSoVLPID8wJ6A2BmI1aJlTGH7HAJZtfpkJU2Txjj1qDgc1VISDKU2+\n" <>
              "pmw+TJnsj8FC805k4tzNjJECgYEAsDI+A2xKTStLqjgq+FWFwE6CReHsYPDSaLjt\n" <>
              "7YnErtcwcTw1fzW0fZjjDEYjR+CLoAoreh8zDcQqVAGu9xi3951nlYy5IgyUNj1o\n" <>
              "LR2fI5iWuXIVlmR0RCYefMfspUpg2DqRUoTPSQXekHLapLq/58H5N4eSMVVrFiKP\n" <>
              "O9mU+fsCgYALD10wthhtfYIMvcTaZ0rAF+X0chBvQzj1YaPbEf0YSocLysotcBjT\n" <>
              "M1m91bRjjR9vBhrg5RDOz3RCIlJ3ipkaE+cfxyUs0+AXwIXIPs2hVJNFRT8d7Z4e\n" <>
              "boWHfxAwHFqoEYzskZCdPArDzshm2bFetCh6Cpw7HsWdtS18X8M8+g==\n" <>
              "-----END RSA PRIVATE KEY-----\n" <>
              ""

  def priv_key(), do: RSA.decode_key(@priv_key)
  def pub_key(), do: RSA.decode_key(@pub_key)

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
