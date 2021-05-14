defmodule FarmbotCore.Firmware.ParameterTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.Parameter

  @how_many_params_there_are 113

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

  test "numbers" do
    numbers = Parameter.numbers()
    assert Enum.count(numbers) == @how_many_params_there_are
    assert is_number(Enum.at(numbers, 0))

    all_numbers? =
      numbers
      |> Enum.map(fn name -> is_number(name) end)
      |> Enum.uniq()
      |> Enum.count() == 1

    assert all_numbers?
  end
end
