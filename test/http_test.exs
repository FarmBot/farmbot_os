defmodule FarmbotTelemetry.HTTPTest do
  use ExUnit.Case
  doctest FarmbotTelemetry.HTTP

  def get(url) do
    FarmbotTelemetry.HTTP.request(:get, {to_charlist(url), []}, [], [])
  end

  @bad_urls [
    "https://expired.badssl.com/",
    "https://wrong.host.badssl.com/",
    "https://self-signed.badssl.com/"
  ]

  test "request/4" do
    case get("https://badssl.com") do
      {:ok, _} -> Enum.map(@bad_urls, fn url -> {:error, _} = get(url) end)
      _ -> IO.warn("Can't reach https://badssl.com; Not testing SSL parts.")
    end
  end
end
