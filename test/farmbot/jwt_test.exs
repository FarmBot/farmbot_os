defmodule Farmbot.JwtTest do
  @moduledoc "Tests Token functions."

  @token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBhZG1pbi5jb20iLCJpYXQiOjE1MDI0Mjc2MDUsImp0aSI6IjA3ZDk1MmRjLWQ2MDktNGRiYi04NTcwLTIxMTNkM2Q2ZWMzOSIsImlzcyI6Ii8vMTkyLjE2OC4yOS4yMDQ6MzAwMCIsImV4cCI6MTUwNTg4MzYwNSwibXF0dCI6IjE5Mi4xNjguMjkuMjA0Iiwib3NfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vYXBpLmdpdGh1Yi5jb20vcmVwb3MvZmFybWJvdC9mYXJtYm90X29zL3JlbGVhc2VzL2xhdGVzdCIsImZ3X3VwZGF0ZV9zZXJ2ZXIiOiJodHRwczovL2FwaS5naXRodWIuY29tL3JlcG9zL0Zhcm1ib3QvZmFybWJvdC1hcmR1aW5vLWZpcm13YXJlL3JlbGVhc2VzL2xhdGVzdCIsImJvdCI6ImRldmljZV8yIn0.twtAOS9PXtkSB-a3Qjm3HrJSM7Nfm7oWOc8d4BFb7nBOaB3eGDUB4sb5u7pjAgMo37egIbAatKKkHlh_o9uNDJvrs9aPsLAn6O8dN_CDCkenjNyrbQjI8i_hjtL28X9AyHLOe1G0A8V8nRs4hZ8x5AcQSH8DkhaaRaBuh-0u1Yesfo7nwFIl34LTCoZ9amrdzHvIn0xP35BaPoEGziqolqtNJ5an2Bps4JGBV_kNSlODwGxPFESHO3uL1PrTgaXkM3_FSZpY7NxbgxC50ok9TspeMRLjluqntzyJG1EadxgHkbVOG0kuPH6R3Pa6UfkDNzBv7DWDHk4mOYPcDdABbQ"

  use ExUnit.Case

  doctest Farmbot.Jwt

  alias Farmbot.Jwt

  setup do
    [token: @token]
  end

  test "decodes a token", %{token: tkn} do
    r = Jwt.decode(tkn)
    assert match?({:ok, %Farmbot.Jwt{}}, r)

    {:ok, token} = r
    assert Jwt.decode!(tkn) == token
    assert token.bot == "device_2"
    assert token.exp == 1_505_883_605
    assert token.iss == "//192.168.29.204:3000"
    assert token.mqtt == "192.168.29.204"
  end

  test "Gives :error when it can't be decoded as bas64", %{token: tkn} do
    [head, _body, foot] = String.split(tkn, ".")
    tkn = [head, "not_a_valid_token", foot] |> Enum.join(".")
    r = Jwt.decode(tkn)
    refute match?({:ok, _}, r)
    assert r == :error
  end

  test "Gives Poison Error when it can't be decoded as json", %{token: tkn} do
    [head, _body, foot] = String.split(tkn, ".")
    not_token = Base.encode64("hello world", padding: false)
    tkn = [head, not_token, foot] |> Enum.join(".")
    r = Jwt.decode(tkn)
    refute match?({:ok, _}, r)
    assert r == {:error, {:invalid, "h", 0}}
  end

  test "raises on bad token because base64", %{token: tkn} do
    [head, _body, foot] = String.split(tkn, ".")
    tkn = [head, "not_a_valid_token", foot] |> Enum.join(".")

    assert_raise RuntimeError, "Failed to base64 decode.", fn ->
      Jwt.decode!(tkn)
    end
  end

  test "Raises on bad json.", %{token: tkn} do
    [head, _body, foot] = String.split(tkn, ".")
    not_token = Base.encode64("hello world", padding: false)
    tkn = [head, not_token, foot] |> Enum.join(".")

    assert_raise RuntimeError, "Failed to json decode.", fn ->
      Jwt.decode!(tkn)
    end
  end
end
