# defmodule Farmbot.SequenceRunnerTest do
#   @moduledoc false
#   use ExUnit.Case, async: true
#   use Amnesia
#   use Farmbot.Sync.Database
#   alias Farmbot.SequenceRunner
#
#   test "runs a sequence" do
#     seq = sequence()
#     {:ok, pid} = SequenceRunner.start_link(seq)
#     assert is_pid(pid)
#   end
#
#   defp sequence do
#     %Sequence{args: %{"is_outdated" => false,
#        "version" => 4},
#      body: [%{"args" => %{"message" => "Bot is at position {{ x }}, {{ y }}, {{ z }}.",
#           "message_type" => "success"}, "kind" => "send_message"}], color: "blue", id: 186,
#      kind: "sequence", name: "errrrp"}
#   end
# end
