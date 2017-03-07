defmodule Farmbot.ImageWatcherTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Auth
  # import Mock

  setup_all do
    Auth.purge_token
    # Makes sure the dirs are empty
    File.rm_rf "/tmp/images"
    File.mkdir "/tmp/images"
    Farmbot.ImageWatcher.force_upload()

    use_cassette "good_login" do
      :ok = Auth.interim("admin@admin.com", "password123", "http://localhost:3000")
      {:ok, token} = Auth.try_log_in
      [token: token]
    end
  end

  test "uploads an image automagically" do
    img_path = "#{:code.priv_dir(:farmbot)}/static/farmbot_logo.png"
    use_cassette "good_image_upload" do
      File.cp! img_path, "/tmp/images/farmbot_logo.png"
    end
  end
end
