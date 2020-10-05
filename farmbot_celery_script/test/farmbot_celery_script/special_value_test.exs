defmodule FarmbotCeleryScript.SpecialValueTest do
  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotCeleryScript.SpecialValue

  setup :verify_on_exit!

  test "soil_height" do
    expect(FarmbotCeleryScript.SysCalls, :fbos_config, 1, fn ->
      {:ok, %{soil_height: 9.87}}
    end)

    value = SpecialValue.soil_height()
    assert value == 9.87
  end
end
