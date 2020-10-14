defmodule FarmbotExt.HTTPCTest do
  # def request(method, params, opts1, opts2) do
  #   :httpc.request(method, params, opts1, opts2)
  # end
  use ExUnit.Case
  alias FarmbotExt.HTTPC

  test "request/4" do
    params = {'http://typo.farm.bot', []}
    assert {:error, error} = HTTPC.request(:head, params, [], [])
  end
end
