defmodule Farmbot.LoggerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Auth
  setup_all do
    Logger.add_backend(Farmbot.Logger)
    use_cassette "good_login" do
      :ok = Auth.interim("admin@admin.com", "password123", "http://localhost:3000")
      {:ok, token} = Auth.try_log_in
      [token: token]
    end
  end

  test "logs fifty messages, then uploads them to the api" do
    require Logger
    use_cassette "good upload" do
      for i <- 0..50 do
        Logger.debug "Farmbot can count to: #{i}"
      end
    end
  end
end
