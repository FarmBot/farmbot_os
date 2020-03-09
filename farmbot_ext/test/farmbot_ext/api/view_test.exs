defmodule FarmbotExt.API.ViewTest do
  use ExUnit.Case

  def render(%{ok: :ok}) do
    :yep
  end

  test "render/2" do
    result = FarmbotExt.API.View.render(__MODULE__, %{ok: :ok})
    assert :yep == result
  end
end
