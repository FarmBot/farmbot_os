defmodule Farmbot.AuthTest do
  use    ExUnit.Case, async: false
  alias  Farmbot.{Context, Auth}

  setup_all do
    context     = Context.new()
    new_context = Farmbot.Test.Helpers.Context.replace_http(context)
    {:ok, auth_pid} = Auth.start_link(new_context, [])
    [cs_context: %{new_context | auth: auth_pid}]
  end

  setup %{cs_context: context} do
    :ok = Auth.purge_token(context.auth)
    :ok
  end

  test "returns nil if no token", %{cs_context: context} do
    thing = Auth.get_token(context.auth)
    assert thing == nil
  end

  test "logs in", %{cs_context: context} do
    {:ok, login_token} = Farmbot.Auth.try_log_in(context.auth)
    assert match?(%Farmbot.Token{}, login_token)
  end

  test "gets the current token", %{cs_context: context} do
    good_interim(context.auth)
    {:ok, login_token} = Farmbot.Auth.try_log_in(context.auth)
    {:ok, token}       = Auth.get_token(context.auth)
    assert login_token == token
  end

  test "gets the current server", %{cs_context: context} do
    good_interim(context.auth)
    {:ok, server} = Auth.get_server(context.auth)
    assert server == "http://localhost:3000"
  end

  # test "doesnt get a token on bad creds", %{cs_context: context} do
  #   bad_interim(context.auth)
  #   {:error, reason} = Auth.try_log_in(context.auth)
  #   assert reason == :bad_password
  # end

  test "logs in aggressivly", %{cs_context: context} do
    good_interim(context.auth)
    {:ok, login_token} = Farmbot.Auth.try_log_in!(context.auth)
    assert match?(%Farmbot.Token{}, login_token)
  end

  test "logs in with creds, then with a secret", %{cs_context: context} do
    good_interim(context.auth)
    {:ok, login_token} = Farmbot.Auth.try_log_in(context.auth)
    assert match?(%Farmbot.Token{}, login_token)

    Process.sleep(100)

    {:ok, new_token} = Farmbot.Auth.try_log_in(context.auth)
    assert match?(%Farmbot.Token{}, new_token)
  end

  # test "factory resets the bot on bad log in", %{cs_context: context} do
  #   use_cassette "bad_login" do
  #     bad_interim(context.auth)
  #     with_mock Farmbot.System, [factory_reset: fn(_reason) -> :ok end] do
  #       Auth.try_log_in!(context.auth)
  #       assert called Farmbot.System.factory_reset(:_)
  #     end
  #   end
  # end

  # test "keeps a backup in case of catastrophic issues secret", %{cs_context: context}do
  #    Auth.purge_token(context.auth)
  #    use_cassette "good_login" do
  #      good_interim(context.auth)
  #      {:ok, login_token} = Farmbot.Auth.try_log_in!(context.auth)
  #      assert match?(%Farmbot.Token{}, login_token)
  #
  #      assert_raise RuntimeError, fn() ->
  #        GenServer.stop(context.auth, :uhhhh?)
  #      end
  #      File.rm("/tmp/secret") # this is the good file
  #      Process.sleep(500)
  #
  #      {:ok, token} = Farmbot.Auth.try_log_in!(context.auth)
  #      assert match?(%Farmbot.Token{}, token)
  #    end
  # end

  # test "forces a new token" do
  #   Auth.purge_token
  #   use_cassette "good_login" do
  #     good_interim(context.auth)
  #     {:ok, login_token} = Farmbot.Auth.try_log_in!
  #     assert match?(%Farmbot.Token{}, login_token)
  #   end
  #
  #   use_cassette "good_login_2" do
  #     send Farmbot.Auth, :new_token
  #     {:ok, token} = Farmbot.Auth.get_token
  #     assert match?(%Farmbot.Token{}, token)
  #   end
  # end

  defp good_interim(auth) do
    :ok = Auth.interim(auth, "admin@admin.com", "password123", "http://localhost:3000")
  end

  defp bad_interim(auth) do
    :ok = Auth.interim(auth, "fail@fail.org", "password", "http://localhost:3000")
  end
end
