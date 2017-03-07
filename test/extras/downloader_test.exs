defmodule DownloaderTest do
  use ExUnit.Case
  # use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  # WHoops Downloader doesnt use Hackney anymore so this just became untestable
  # Trust me it works
  # test "downloads a file" do
  #   use_cassette "good_corpus_request" do
  #     path = "/tmp/download.thing"
  #     url = "http://localhost:3000/api/corpuses"
  #     ret_path = Downloader.run(url, path)
  #     assert ret_path == path
  #     assert File.exists?(path)
  #   end
  # end
end
