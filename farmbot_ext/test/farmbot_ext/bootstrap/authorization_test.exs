defmodule FarmbotExt.Bootstrap.AuthorizationTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotCore.JSON
  alias FarmbotExt.Bootstrap.Authorization

  test "build_payload/1" do
    fake_secret =
      %{just: "a test"}
      |> JSON.encode!()
      |> Base.encode64()

    {:ok, result} = Authorization.build_payload(fake_secret)
    expected = "{\"user\":{\"credentials\":\"ZXlKcWRYTjBJam9pWVNCMFpYTjBJbjA9\"}}"
    assert result == expected
  end
end
