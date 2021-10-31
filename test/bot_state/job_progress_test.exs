defmodule FarmbotCore.BotState.JobProgressTest do
  use ExUnit.Case
  alias FarmbotCore.BotState.JobProgress

  test "serialization of percentages" do
    assert inspect(%JobProgress.Percent{percent: 42}) == "#Percent<42>"
  end
end
