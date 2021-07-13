defmodule FarmbotCeleryScript.SpecialValueTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotCeleryScript.SpecialValue

  setup :verify_on_exit!

  test "soil_height" do
    most_recent = %{x: 1, y: 1, updated_at: ~U[2021-07-12 12:34:56.789000Z]}
    outlier = %{x: 100, y: 200, updated_at: ~U[2021-07-10 10:34:56.789000Z]}

    # SCENARIO: One point in the garden has been measure 7 times over 7 days,
    #           but we only want the most recent reading.
    list = [
      %{x: 1, y: 1, updated_at: ~U[2021-07-06 06:34:56.789000Z]},
      %{x: 2, y: 1, updated_at: ~U[2021-07-07 07:34:56.789000Z]},
      %{x: 3, y: 1, updated_at: ~U[2021-07-08 08:34:56.789000Z]},
      %{x: 1, y: 1, updated_at: ~U[2021-07-09 09:34:56.789000Z]},
      %{x: 1, y: 2, updated_at: ~U[2021-07-10 10:34:56.789000Z]},
      outlier,
      %{x: 1, y: 3, updated_at: ~U[2021-07-11 11:34:56.789000Z]},
      most_recent
    ]

    expected = [most_recent, outlier]

    assert SpecialValue.index_by_location(list) == expected
  end
end
