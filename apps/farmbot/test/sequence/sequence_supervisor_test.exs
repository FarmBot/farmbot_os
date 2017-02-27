# defmodule Sequence.SupervisorTest do
#   @moduledoc false
#   use ExUnit.Case, async: true
#   use Amnesia
#   alias Sequence.Supervisor, as: S
#   use Farmbot.Sync.Database
#
#   test "starts and stops sequence" do
#     {:ok, pid} = S.add_child(sequence(), Timex.now())
#     S.remove_child(sequence())
#     state = S.get_state
#     assert is_pid(pid)
#     assert state.running == nil
#   end
#
#   test "starts and queues a sequence" do
#     sA = sequence()
#     sB = %{sA | id: 123}
#     now = Timex.now()
#     {:ok, respA} = S.add_child(sA, now)
#     {:ok, respB} = S.add_child(sB, now)
#
#     S.remove_child(sA)
#     S.remove_child(sB)
#
#     state = S.get_state
#     assert is_pid(respA)
#     assert respB == :queued
#     assert state.running == nil
#   end
#
#   test "starts, finishes a sequence, then starts the next " do
#     sA = sequence()
#     sB = %{sA | id: 123}
#     now = Timex.now()
#     {:ok, pidA} = S.add_child(sA, now)
#     {:ok, :queued} = S.add_child(sB, now)
#     GenServer.stop(pidA, :normal)
#     state = S.get_state
#     running = state.running
#     {pidB, sequence} = running
#     assert pidA != pidB
#   end
#
#   defp sequence do
#     %Sequence{args: %{"is_outdated" => false,
#        "version" => 4},
#      body: [], color: "blue", device_id: nil, id: 186,
#      kind: "sequence", name: "New Sequence"}
#   end
# end
