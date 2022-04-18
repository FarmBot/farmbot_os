defmodule FarmbotOS.SequenceOnBoot do
  @moduledoc """
  Request an existing Sequence to be scheduled for execution at earliest opportunity.

  Process code which can be run by a "fire-and-forget" Supervised Task.
  """

  def schedule_boot_sequence() do
    with "synced" <-
           FarmbotOS.BotState.subscribe().informational_settings.sync_status do
      do_schedule_sequence()
    else
      _not_yet ->
        await_fbos_synced()
    end
  end

  defp await_fbos_synced() do
    receive do
      {FarmbotOS.BotState,
       %{
         changes: %{
           informational_settings: %{changes: %{sync_status: sync_status}}
         }
       }} ->
        with "synced" <- sync_status do
          do_schedule_sequence()
        else
          _not_yet ->
            await_fbos_synced()
        end
    end
  end

  defp do_schedule_sequence do
    boot_sequence_id = FarmbotOS.Asset.fbos_config(:boot_sequence_id)

    if not is_nil(boot_sequence_id) do
      FarmbotOS.Logger.success(
        1,
        "FarmBot is booted. Executing boot sequence..."
      )

      boot_sequence_ast =
        FarmbotOS.Celery.SysCallGlue.get_sequence(boot_sequence_id)

      now = DateTime.utc_now()

      Process.whereis(FarmbotOS.Celery.Scheduler)
      |> FarmbotOS.Celery.Scheduler.schedule(boot_sequence_ast, now, %{})
    else
      FarmbotOS.Logger.success(1, "FarmBot is booted.")
    end
  end
end
