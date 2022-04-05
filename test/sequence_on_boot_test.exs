defmodule FarmbotOS.SequenceOnBootTest do
  alias FarmbotOS.SequenceOnBoot

  use ExUnit.Case
  use Mimic

  test "schedule_boot_sequence" do
    expect(FarmbotOS.Asset, :fbos_config, 1, fn _id -> 1 end)

    sequence_ast = %{meta: %{sequence_name: "My Sequence"}}

    expect(FarmbotOS.Celery.SysCallGlue, :get_sequence, 1, fn _id ->
      sequence_ast
    end)

    expect(FarmbotOS.Celery.Scheduler, :schedule, 1, fn _pid, ast, _now, _ ->
      assert ast == sequence_ast
    end)

    SequenceOnBoot.schedule_boot_sequence()
  end
end
