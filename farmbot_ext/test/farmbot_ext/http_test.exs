defmodule FarmbotExt.HTTPTest do
  # def request(method, params, opts1, opts2) do
  #   :httpc.request(method, params, opts1, opts2)
  # end
  use ExUnit.Case
  alias FarmbotExt.HTTP

  test "request/4" do
    params = {'http://typo.farm.bot', []}
    assert {:error, error} = HTTP.request(:head, params, [], [])
  end
end
