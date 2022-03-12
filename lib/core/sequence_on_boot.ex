defmodule FarmbotOS.SequenceOnBoot do
  @moduledoc """
  Send an existing Sequence to be scheduled for execution.
  """

  def schedule_boot_sequence() do
    boot_sequence_id = FarmbotOS.Asset.fbos_config(:boot_sequence_id)
    if not is_nil(boot_sequence_id) do
      boot_sequence_ast = FarmbotOS.Celery.SysCallGlue.get_sequence(boot_sequence_id)
      now = DateTime.utc_now()
      Process.whereis(FarmbotOS.Celery.Scheduler)
        |> FarmbotOS.Celery.Scheduler.schedule(boot_sequence_ast, now, %{})
    end
  end

end
