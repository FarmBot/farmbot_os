defmodule Farmbot.SyncTest do
  use ExUnit.Case
  alias Farmbot.Auth
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    use_cassette "good_login" do
      :ok = Auth.interim("admin@admin.com", "password123", "http://localhost:3000")
      {:ok, token} = Auth.try_log_in
      [token: token]
    end
  end

  # test "syncs the bot" do
  #   use_cassette "good_sync" do
  #     {:ok, so} = Farmbot.Sync.sync
  #     assert is_map(so)
  #   end
  # end
end
