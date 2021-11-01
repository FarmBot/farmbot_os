defmodule FarmbotOS.SysCalls.ChangeOwnershipTest do
  require Helpers

  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.ChangeOwnership
  alias FarmbotOS.Bootstrap.Authorization

  test "replace_credentials(email, secret, server)" do
    Helpers.expect_log("Replacing credentials")

    expect(FarmbotOS.Config, :update_config_value, 5, fn
      :string, "authorization", "token", nil -> :ok
      :string, "authorization", "server", "server" -> :ok
      :string, "authorization", "secret", "secret" -> :ok
      :string, "authorization", "password", nil -> :ok
      :string, "authorization", "email", "email" -> :ok
    end)

    assert :ok ==
             ChangeOwnership.Support.replace_credentials(
               "email",
               "secret",
               "server"
             )
  end

  test "change_ownership(email, secret, server) - ok" do
    expect(ChangeOwnership.Support, :replace_credentials, 1, fn email,
                                                                secret,
                                                                server ->
      assert email == "email"
      assert secret == "secret"
      assert server == "server"
      :ok
    end)

    expect(ChangeOwnership.Support, :clean_assets, 1, fn ->
      :ok
    end)

    expect(ChangeOwnership.Support, :soft_restart, 1, fn ->
      :ok
    end)

    expect(Authorization, :authorize_with_secret, 1, fn _, _, _ ->
      {:ok, "test12344"}
    end)

    ChangeOwnership.change_ownership("email", "secret", "server")
  end

  test "change_ownership(email, secret, server) - error" do
    expect(Authorization, :authorize_with_secret, 1, fn email, secret, server ->
      assert email == "email"
      assert secret == "secret"
      assert server == "server"
      {:error, "nope"}
    end)

    ChangeOwnership.change_ownership("email", "secret", "server")
  end
end
