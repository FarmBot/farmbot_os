defmodule FarmbotCore.FarmEventWorker.SequenceTest do
  use ExUnit.Case

  alias FarmbotCore.FarmEventWorker.SequenceEvent

  test "init/1" do
    arry = [:farm_event, :args]
    {:ok, %{farm_event: :farm_event, args: :args}} = SequenceEvent.init(arry)
    assert_receive :schedule, 1000
  end
end
