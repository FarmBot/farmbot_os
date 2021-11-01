defmodule FarmbotOS.TimeUtilsTest do
  alias FarmbotOS.TimeUtils
  use ExUnit.Case

  test "compare_datetimes" do
    early = ~U[2021-09-27 12:34:56.780000Z]
    late = ~U[2021-09-28 12:34:56.780000Z]
    assert :eq == TimeUtils.compare_datetimes(early, early)
    assert :gt == TimeUtils.compare_datetimes(late, early)
    assert :lt == TimeUtils.compare_datetimes(early, late)
  end
end
