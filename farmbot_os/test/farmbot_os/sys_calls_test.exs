defmodule FarmbotOS.SysCallsTest do
  use ExUnit.Case, async: true
  import Mox
  alias FarmbotOS.SysCalls
  # alias FarmbotCore.Asset

  alias FarmbotCore.Asset.{
    Command,
    Repo,
    Sequence
  }

  setup :verify_on_exit!

  test "get_sequence(id)" do
    _ = Repo.delete_all(Sequence)
    fake_id = 28
    fake_name = "X"

    fake_params = %{
      id: fake_id,
      name: fake_name,
      args: %{
        sequence_name: fake_name
      },
      kind: "sequence",
      body: []
    }

    assert SysCalls.get_sequence(fake_id) == {:error, "sequence not found"}

    %Sequence{id: id} =
      %Sequence{}
      |> Sequence.changeset(fake_params)
      |> Repo.insert!()

    assert id == fake_id
    result = SysCalls.get_sequence(fake_id)
    assert result.args == fake_params[:args]
    assert result.kind == :sequence
    assert result.body == fake_params[:body]
  end

  test "coordinate()" do
    expected = %{x: 1, y: 2, z: 3}
    actual = SysCalls.coordinate(1, 2, 3)
    assert expected == actual
  end

  test "nothing" do
    assert SysCalls.nothing() == nil
  end

  test "install_first_party_farmware()" do
    expected = {:error, "install_first_party_farmware not yet supported"}
    actual = SysCalls.install_first_party_farmware()
    assert expected == actual
  end
end
