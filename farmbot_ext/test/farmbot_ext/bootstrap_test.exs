defmodule FarmbotExt.BootstrapTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotExt.Bootstrap
  alias FarmbotExt.Bootstrap.Authorization
  setup :verify_on_exit!

  test "performs a factory reset if the email is wrong" do
    expect(Bootstrap.Authorization, :authorize_with_password, 1, fn
      _email, _password, _server ->
        {:error, "Bad email or password."}
    end)

    expect(FarmbotCeleryScript.SysCalls, :factory_reset, 1, fn "farmbot_os" -> :ok end)
    assert Bootstrap.try_auth("", "", "", "") == {:noreply, nil, 0}
  end

  test "reauthorizes as needed" do
    expect(FarmbotCore.Config, :get_config_value, 3, fn
      :string, "authorization", "email" -> "the_email"
      :string, "authorization", "server" -> "the_server"
      :string, "authorization", "secret" -> "the_secret"
    end)

    expect(Authorization, :authorize_with_secret, 1, fn "the_email", "the_secret", "the_server" ->
      {:ok, "the_token"}
    end)

    expect(FarmbotCore.Config, :update_config_value, 1, fn
      :string, "authorization", "token", "the_token" -> :ok
    end)

    {:ok, "the_token"} = Bootstrap.reauth()
  end
end
