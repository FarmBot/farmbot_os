defmodule Farmbot.HTTPTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Auth
  alias Farmbot.HTTP
  # import Mock

  setup_all do
    use_cassette "good_login" do
      :ok = Auth.interim("admin@admin.com", "password123", "http://localhost:3000")
      {:ok, token} = Auth.try_log_in
      [token: token]
    end
  end

  test "makes an api request" do
    use_cassette "good_corpus_request" do
      {:ok, resp} = HTTP.get "/api/corpuses"
      assert match?(%HTTPoison.Response{}, resp)
    end
  end
end
