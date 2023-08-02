defmodule FarmbotOS.Bootstrap.AuthorizationTest do
  require Helpers

  use ExUnit.Case
  use Mimic

  alias FarmbotOS.JSON
  alias FarmbotOS.Bootstrap.Authorization
  alias FarmbotOS.JSON

  test "build_payload/1" do
    fake_secret =
      %{just: "a test"}
      |> JSON.encode!()
      |> Base.encode64()

    {:ok, result} = Authorization.build_payload(fake_secret)

    expected =
      "{\"user\":{\"credentials\":\"ZXlKcWRYTjBJam9pWVNCMFpYTjBJbjA9\"}}"

    assert result == expected
  end

  test "build_secret/3" do
    email = "test@test.com"
    password = "password123"
    pub_key = Authorization.rsa_decode_key(Helpers.pub_key())
    cyphertext = Authorization.build_secret(email, password, pub_key)
    priv_key = Authorization.rsa_decode_key(Helpers.priv_key())

    %{
      "email" => email_result,
      "password" => password_result,
      "version" => version
    } =
      JSON.decode!(Authorization.rsa_decrypt(cyphertext, {:private, priv_key}))

    assert email_result == email
    assert password_result == password
    assert version == 1
  end

  test "do_request/2" do
    url = ~c"https://geocities.com"
    headers = [{"Content-Type", "application/json"}]
    request = {:get, url, "", headers}
    state = %{backoff: 5000, log_dispatch_flag: false}

    expect(FarmbotOS.HTTP, :request, 1, fn method, req, opt1, opt2 ->
      assert method == :get
      assert req == {url, [{~c"Content-Type", ~c"application/json"}]}
      assert opt1 == []
      assert opt2 == [body_format: :binary]
      {:ok, {{{}, 200, {}}, {}, "body123"}}
    end)

    result = Authorization.do_request(request, state)
    assert {:ok, "body123"} == result
  end
end
