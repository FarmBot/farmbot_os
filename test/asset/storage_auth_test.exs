defmodule FarmbotOS.Asset.StorageAuthTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.StorageAuth

  @expected_keys [:verb, :url, :form_data]

  test "render/1" do
    result =
      StorageAuth.render(%StorageAuth{form_data: %StorageAuth.FormData{}})

    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
