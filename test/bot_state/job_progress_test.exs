defmodule FarmbotOS.BotState.JobProgressTest do
  use ExUnit.Case
  alias FarmbotOS.BotState.JobProgress

  test "serialization of percentages" do
    assert inspect(%JobProgress.Percent{percent: 42}) == "#Percent<42>"
  end
end
