defmodule Farmbot.AuthTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Auth
  import Mock

  setup_all do
    :ok
  end

  setup do
    :ok = Auth.purge_token
    :ok
  end

  test "returns nil if no token" do
    thing = Auth.get_token
    assert thing == nil
  end

  test "logs in" do
    good_interim()
    {:ok, login_token} = Farmbot.Auth.try_log_in
    assert match?(%Farmbot.Token{}, login_token)
  end

  test "gets the current token" do
    good_interim()
    {:ok, login_token} = Farmbot.Auth.try_log_in
    {:ok, token} = Auth.get_token
    assert login_token == token
  end

  test "gets the current server" do
    good_interim()
    {:ok, server} = Auth.get_server
    assert server == "http://localhost:3000"
  end

  test "doesnt get a token on bad creds" do
    bad_interim()
    {:error, reason} = Auth.try_log_in
    assert reason == :bad_password
  end

  test "logs in aggressivly" do
    good_interim()
    {:ok, login_token} = Farmbot.Auth.try_log_in!
    assert match?(%Farmbot.Token{}, login_token)
  end

  test "logs in with creds, then with a secret" do
    good_interim()
    {:ok, login_token} = Farmbot.Auth.try_log_in
    assert match?(%Farmbot.Token{}, login_token)

    Process.sleep(100)

    {:ok, new_token} = Farmbot.Auth.try_log_in
    assert match?(%Farmbot.Token{}, new_token)
  end

  test "factory resets the bot on bad log in" do
    bad_interim()
    with_mock Farmbot.System, [factory_reset: fn -> :ok end] do
      Auth.try_log_in!()
      assert called Farmbot.System.factory_reset()
    end
  end

  defp good_interim do
    :ok = Auth.interim("admin@admin.com", "password123", "http://localhost:3000")
  end

  defp bad_interim do
    :ok = Auth.interim("fail@fail.org", "password", "http://localhost:3000")
  end
end
