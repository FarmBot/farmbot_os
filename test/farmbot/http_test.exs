defmodule Farmbot.HTTPTest do
  use Farmbot.Tets.HTTPTemplate, async: false
  alias Farmbot.Auth
  alias Farmbot.HTTP
  alias Farmbot.Context

  test "mocks any old http request", %{cs_context: context} do
    # This isnt really testing the client lib, but the testing lib i guess?
    mock = %{headers: [], body: "hello world", status_code: 200}
    mock_http mock, fn() ->
      {:ok, f} = HTTP.get(context, "http://google.com")
      assert f.body        == mock.body
      assert f.status_code == mock.status_code
      assert f.headers     == mock.headers
    end
  end

  test "mocks an api http request", %{cs_context: context} do
    mock = %{headers: [], body: "hey", status_code: 404}
    mock_api mock, context, fn() ->
      {:ok, response} = HTTP.get context, "/api/points/1"
      inspect response.body == "hey"
      assert response.body        == mock.body
      assert response.status_code == mock.status_code
      assert response.headers     == mock.headers
    end
  end


  # test "makes an api request" do
  #   use_cassette "good_corpus_request" do
  #     {:ok, resp} = HTTP.get "/api/corpuses"
  #     assert match?(%HTTPoison.Response{}, resp)
  #   end
  # end
  #
  # test "uploads a file to the api and google cloud storage" do
  #   use_cassette "good_image_upload" do
  #     img_path = "#{:code.priv_dir(:farmbot)}/static/farmbot_logo.png"
  #     {:ok, resp} = HTTP.upload_file(img_path)
  #     assert match?(%HTTPoison.Response{}, resp)
  #   end
  # end
  #
  test "wont upload if an image doesnt exist" do
    img_path = "#{:code.priv_dir(:farmbot)}/static/fake_farmbot_logo.png"
    assert_raise(RuntimeError, "File not found", fn -> HTTP.upload_file(img_path) end)
  end

end
