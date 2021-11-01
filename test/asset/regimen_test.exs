defmodule FarmbotOS.Asset.RegimenTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.Regimen

  @expected_keys [:id, :name, :regimen_items, :body]

  def regimen_json() do
    File.read!("fixtures/regimens/regimen_with_variables.json")
    |> FarmbotOS.JSON.decode!()
  end

  test "loading of body" do
    json = regimen_json()
    assert Enum.count(json["body"]) == 3

    changeset = Regimen.changeset(%Regimen{}, json)
    assert changeset.valid?

    result = Ecto.Changeset.apply_changes(changeset)
    assert is_list(result.body)
  end

  test "render/1" do
    result = Regimen.render(%Regimen{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
