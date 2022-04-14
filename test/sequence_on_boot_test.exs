defmodule FarmbotOS.SequenceOnBootTest do
  alias FarmbotOS.SequenceOnBoot

  use ExUnit.Case
  use Mimic

  require Helpers

  test "schedule_boot_sequence: synced" do
    expect(FarmbotOS.Asset, :fbos_config, 1, fn _id -> 1 end)

    expect(FarmbotOS.BotState, :subscribe, 1, fn ->
      %{
        informational_settings: %{
          sync_status: "synced"
        }
      }
    end)

    sequence_ast = %{meta: %{sequence_name: "My Sequence"}}

    expect(FarmbotOS.Celery.SysCallGlue, :get_sequence, 1, fn _id ->
      sequence_ast
    end)

    expect(FarmbotOS.Celery.Scheduler, :schedule, 1, fn _pid, ast, _now, _ ->
      assert ast == sequence_ast
    end)

    Helpers.expect_log("FarmBot is booted. Executing boot sequence...")

    SequenceOnBoot.schedule_boot_sequence()
  end

  test "schedule_boot_sequence: no boot sequence" do
    expect(FarmbotOS.Asset, :fbos_config, 1, fn _id -> nil end)

    expect(FarmbotOS.BotState, :subscribe, 1, fn ->
      %{
        informational_settings: %{
          sync_status: "synced"
        }
      }
    end)

    reject(FarmbotOS.Celery.SysCallGlue, :get_sequence, 1)
    reject(FarmbotOS.Celery.Scheduler, :schedule, 3)

    Helpers.expect_log("FarmBot is booted.")

    SequenceOnBoot.schedule_boot_sequence()
  end

  test "schedule_boot_sequence: not yet" do
    %Task{pid: pid} =
      task =
      Task.async(
        SequenceOnBoot,
        :schedule_boot_sequence,
        []
      )

    send(
      pid,
      {FarmbotOS.BotState,
       %{
         changes: %{
           informational_settings: %{changes: %{sync_status: "syncing"}}
         }
       }}
    )

    try do
      Task.await(task)
    catch
      _kind, _err -> nil
    end
  end

  test "schedule_boot_sequence: on status update" do
    %Task{pid: pid} =
      task =
      Task.async(
        SequenceOnBoot,
        :schedule_boot_sequence,
        []
      )

    send(
      pid,
      {FarmbotOS.BotState,
       %{
         changes: %{
           informational_settings: %{changes: %{sync_status: "synced"}}
         }
       }}
    )

    Task.await(task)
  end
end
