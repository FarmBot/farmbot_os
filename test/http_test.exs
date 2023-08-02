defmodule FarmbotOS.HTTPTest do
  use ExUnit.Case
  doctest FarmbotOS.HTTP
  alias FarmbotOS.HTTP

  def get(url) do
    FarmbotOS.HTTP.request(:get, {to_charlist(url), []}, [], [])
  end

  @bad_urls [
    "https://expired.badssl.com/",
    "https://wrong.host.badssl.com/",
    "https://self-signed.badssl.com/"
  ]

  test "request/4 - SSL stuff" do
    case get("https://badssl.com") do
      {:ok, _} -> Enum.map(@bad_urls, fn url -> {:error, _} = get(url) end)
      _ -> IO.warn("Can't reach https://badssl.com; Not testing SSL parts.")
    end
  end

  test "request/4" do
    params = {~c"http://typo.farm.bot", []}
    assert {:ok, _error} = HTTP.request(:head, params, [], [])
  end
end
