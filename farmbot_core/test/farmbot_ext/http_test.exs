defmodule FarmbotTelemetry.HTTPTest do
  use ExUnit.Case
  alias FarmbotTelemetry.HTTP

  test "request/4" do
    params = {'http://typo.farm.bot', []}
    assert {:error, _error} = HTTP.request(:head, params, [], [])
  end
end
