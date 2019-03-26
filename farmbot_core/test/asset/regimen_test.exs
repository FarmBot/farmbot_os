defmodule FarmbotCore.Asset.RegimenTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.Regimen

  def regimen_json() do
    File.read!("fixtures/regimens/regimen_with_variables.json")
    |> FarmbotCore.JSON.decode!()
  end

  test "loading of body" do
    json = regimen_json()
    assert Enum.count(json["body"]) == 3

    changeset = Regimen.changeset(%Regimen{}, json)
    assert changeset.valid?

    result = Ecto.Changeset.apply_changes(changeset)
    assert is_list(result.body)
  end
end
