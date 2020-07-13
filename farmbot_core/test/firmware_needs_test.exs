defmodule FarmbotCore.FirmwareNeedsTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.FirmwareNeeds

  test "tracks firmware needs in memory" do
    {:ok, pid} = FirmwareNeeds.start_link([], [])

    assert FirmwareNeeds.open?(pid)
    assert FirmwareNeeds.flash?(pid)

    FirmwareNeeds.open(true, pid)
    assert FirmwareNeeds.open?(pid)

    FirmwareNeeds.open(false, pid)
    refute FirmwareNeeds.open?(pid)

    FirmwareNeeds.flash(true, pid)
    assert FirmwareNeeds.flash?(pid)

    FirmwareNeeds.flash(false, pid)
    refute FirmwareNeeds.flash?(pid)
  end
end
