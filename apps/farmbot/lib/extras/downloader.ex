defmodule Downloader do
  @moduledoc """
    I found most of this as a very helpfulk gist.
    If i find it again I will link to it
    because it was very helpful
  """
  require Logger
  # TODO MOVE ME

  def run(url, path) do
    {:ok, %HTTPoison.Response{body: thing}} = HTTPoison.get(url, [], [follow_redirect: true])
    File.write!(path, thing)
    path
  end
end
