defmodule TokenTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Farmbot.Token

  test "creates a token" do
    url = Faker.Internet.url
    bot_name = Faker.Name.title
    date_thing = 123456
    email = Faker.Internet.email
    decoded_json =
      %{"encoded" => "asdfasdfasdfasdfasdfasdflalalalalas",
         "unencoded" =>
          %{"bot" => bot_name,
            "exp" => date_thing,
            "fw_update_server" => url,
            "os_update_server" => url,
            "iat" => date_thing,
            "iss" => url,
            "jti" => "123456",
            "mqtt" => url,
            "sub" => email}}

    {:ok, f} = Token.create(decoded_json)
    une = f.unencoded
    assert(f.encoded == "asdfasdfasdfasdfasdfasdflalalalalas")
    assert(une.bot == bot_name)
    assert une.exp == date_thing
    assert une.iat == date_thing
    assert une.fw_update_server == url
    assert une.os_update_server == url
    assert une.sub == email
  end

  test "raises an execption on a bad token" do
    bad_json =
      %{"encoded" => "abc",
        "unencoded" => "arbitrary code injection would be cool."}

    assert_raise RuntimeError, fn ->
      Token.create!(bad_json)
    end
  end
end
