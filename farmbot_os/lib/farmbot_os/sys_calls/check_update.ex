defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotOS.UpdateSupport

  alias FarmbotCore.{
    BotState.JobProgress.Percent,
    BotState
  }

  def check_update() do
    progress(nil, 1)

    try do
      UpdateSupport.get_target()
      |> progress(25)
      |> UpdateSupport.download_meta_data()
      |> progress(50)
      |> Map.get("image_url", nil)
      |> progress(75)
      |> UpdateSupport.install_update()
      |> progress(100)

      FarmbotCore.Logger.debug(3, "Going down for reboot.")
      FarmbotCeleryScript.SysCalls.reboot()
    after
      # If anything crashes, be sure to clean up artifacts
      # and progress bars.
      progress(nil, 100)
    end

    :ok
  end

  defp progress(passthru, 100) do
    set_progress(passthru, %Percent{percent: 100, status: "complete"})
  end

  defp progress(passthru, percent) do
    set_progress(passthru, %Percent{percent: percent})
  end

  defp set_progress(passthru, percent) do
    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", percent)
    end

    passthru
  end
end
