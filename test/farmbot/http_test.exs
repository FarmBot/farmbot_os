defmodule Farmbot.HTTPTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Auth
  alias Farmbot.HTTP
  alias Farmbot.CeleryScript.Ast.Context

  setup_all do
    context = Context.new()
    use_cassette "good_login" do
      :ok = Auth.interim(context.auth, "admin@admin.com", "password123", "http://localhost:3000")
      {:ok, token} = Auth.try_log_in(context.auth)
      [token: token, cs_context: context]
    end
  end

  test "makes an api request" do
    use_cassette "good_corpus_request" do
      {:ok, resp} = HTTP.get "/api/corpuses"
      assert match?(%HTTPoison.Response{}, resp)
    end
  end

  test "uploads a file to the api and google cloud storage" do
    use_cassette "good_image_upload" do
      img_path = "#{:code.priv_dir(:farmbot)}/static/farmbot_logo.png"
      {:ok, resp} = HTTP.upload_file(img_path)
      assert match?(%HTTPoison.Response{}, resp)
    end
  end

  test "wont upload if an image doesnt exist" do
    img_path = "#{:code.priv_dir(:farmbot)}/static/fake_farmbot_logo.png"
    assert_raise(RuntimeError, "File not found", fn -> HTTP.upload_file(img_path) end)
  end

end
