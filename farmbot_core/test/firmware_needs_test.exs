defmodule FarmbotCore.FirmwareNeedsTest do
  use ExUnit.Case
  alias FarmbotCore.FirmwareNeeds

  test "tracks firmware needs in memory" do
    {:ok, pid} = FirmwareNeeds.start_link([], [])

    assert FirmwareNeeds.open?(pid)
    # HACK: v13.1.0 had serious firmware problems. We decided
    # to do a re-write. We wanted to do one last release before
    # the re-write. To quickly patch the problems, we decided to
    # simply stub `FirmwareNeeds.flash?` to always return false.
    assert !FirmwareNeeds.flash?(pid)

    FirmwareNeeds.flash(true, pid)
    assert !FirmwareNeeds.flash?(pid)

    FirmwareNeeds.open(true, pid)
    assert FirmwareNeeds.open?(pid)

    FirmwareNeeds.open(false, pid)
    refute FirmwareNeeds.open?(pid)

    FirmwareNeeds.flash(false, pid)
    refute FirmwareNeeds.flash?(pid)
  end
end
