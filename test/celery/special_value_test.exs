defmodule FarmbotOS.Celery.SpecialValueTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.SpecialValue
  require Helpers

  setup :verify_on_exit!

  test "soil_height() (less than three soil height samples)" do
    expected =
      "Need at least 3 soil height samples to guess" <>
        " soil height. Using fallback value instead: 0.0"

    Helpers.expect_log(expected)
    expect(FarmbotOS.Asset.Repo, :all, 1, fn _sql -> [] end)
    refute FarmbotOS.Asset.fbos_config(:soil_height)
    assert 0.0 == SpecialValue.soil_height(%{x: 0.0, y: 0.0})
  end

  test "soil_height() (more than three soil height samples)" do
    fakes =
      [
        {50.59, 86.69, -307.31},
        {17.99, 93.42, -326.95},
        {26.04, 48.05, -315.5},
        {6.46, 18.18, -309.49},
        {20.64, 97.16, -313.68},
        {30.97, 14.73, -326.0},
        {32.93, 60.65, -319.6},
        {35.66, 22.38, -307.95},
        {13.56, 86.7, -319.78},
        {4.55, 92.83, 325.88}
      ]
      |> Enum.map(fn {x, y, z} ->
        %{
          x: x * 10,
          y: y * 10,
          z: z,
          updated_at: ~U[2021-07-06 06:34:56.789000Z],
          meta: %{"at_soil_level" => "true"}
        }
      end)

    expect(FarmbotOS.Asset.Repo, :all, 1, fn _sql -> fakes end)
    assert -309.68 == SpecialValue.soil_height(%{x: 25.0, y: 75.0})
  end

  test "index_by_location(list)" do
    most_recent = %{x: 1, y: 1, updated_at: ~U[2021-07-12 12:34:56.789000Z]}
    outlier = %{x: 100, y: 200, updated_at: ~U[2021-07-10 10:34:56.789000Z]}

    # SCENARIO: One point in the garden has been measure 7 times over 7 days,
    #           but we only want the most recent reading.
    list = [
      "The function discards malformed values.",
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
