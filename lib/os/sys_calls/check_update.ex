defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotOS.Logger

  alias FarmbotOS.{
    UpdateSupport,
    UpdateProgress
  }

  def check_update() do
    if UpdateSupport.in_progress?() do
      dont_check_update()
    else
      do_check_update()
    end
  end

  def dont_check_update() do
    {:error, "Installation already started. Please wait or reboot."}
  end

  def do_check_update() do
    {:ok, progress_pid} = UpdateProgress.start_link([])

    with :ok <- UpdateSupport.install_update(url_or_nil()) do
      done(progress_pid)
    else
      error -> terminate(error, progress_pid)
    end
  end

  def done(progress_pid) do
    UpdateProgress.set(progress_pid, 100)
    FarmbotOS.Celery.SysCallGlue.reboot()
  end

  # Try to find the upgrade image URL (might be `nil`)
  def url_or_nil() do
    UpdateSupport.get_target()
    |> UpdateSupport.download_meta_data()
    |> Map.get("image_url", nil)
  end

  def terminate({:error, error}, pid), do: terminate(error, pid)

  def terminate(error, progress_pid) do
    FarmbotOS.Logger.debug(3, "Upgrade halted: #{inspect(error)}")
    UpdateProgress.set(progress_pid, 100)
    {:error, error}
  end

  def uptime_hotfix(uptime_seconds) do
    days = uptime_seconds / 86400

    if days > 31 do
      FarmbotOS.Logger.debug(3, "Rebooting after #{days} days of uptime.")
      FarmbotOS.SysCalls.reboot()
    end
  end
end
