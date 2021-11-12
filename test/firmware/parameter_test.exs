defmodule FarmbotOS.Firmware.ParameterTest do
  use ExUnit.Case
  alias FarmbotOS.Firmware.Parameter

  @how_many_params_there_are 118

  test "decoding" do
    assert 61 == Parameter.translate(:movement_min_spd_x)
  end

  test "encoding" do
    assert :movement_max_spd_z == Parameter.translate(73)
  end

  test "names" do
    names = Parameter.names()
    assert Enum.count(names) == @how_many_params_there_are
    assert is_atom(Enum.at(names, 0))

    all_atoms? =
      names
      |> Enum.map(fn name -> is_atom(name) end)
      |> Enum.uniq()
      |> Enum.count() == 1

    assert all_atoms?
  end
end
