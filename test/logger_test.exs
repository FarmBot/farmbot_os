defmodule Farmbot.LoggerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Auth
  require Logger

  setup_all do
    Logger.add_backend(Farmbot.Logger)
    use_cassette "good_login" do
      :ok = Auth.interim("admin@admin.com", "password123", "http://localhost:3000")
      {:ok, token} = Auth.try_log_in
      [token: token]
    end
  end

  test "logs fifty messages, then uploads them to the api" do
    Logger.flush
    use_cassette "good_log_upload" do
      for i <- 0..51 do
        Logger.debug "Farmbot can count to: #{i}"
      end
      Process.sleep(3000)

      r = Farmbot.HTTP.get! "/api/logs"
      body = Poison.decode!(r.body)
      assert Enum.count(body) >= 49
    end
  end

  test "gets the logger state" do
    Logger.flush

    Logger.debug "hey world"
    state = GenEvent.call(Logger, Farmbot.Logger, :get_state)
    assert is_list(state.logs)
    [log] = state.logs
    assert log.message == "hey world"
  end
end
