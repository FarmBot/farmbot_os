defmodule FarmbotExt.FarmbotExtTest do
  use ExUnit.Case

  test "catche bad mock implementations" do
    boom = fn ->
      FarmbotExt.fetch_impl!(__MODULE__, :dasdasdads)
    end

    expected = ~r/No default dasdasdads implementation was provided/
    assert_raise Mix.Error, expected, boom
  end
end
