defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotOS.UpdateSupport

  alias FarmbotCore.{
    BotState.JobProgress.Percent,
    BotState
  }

  def check_update() do
    # Get the progress spinner spinning...
    progress(nil, 1)

    # Try to find the upgrade image URL (might be `nil`)
    url_or_nil =
      UpdateSupport.get_target()
      |> progress(25)
      |> UpdateSupport.download_meta_data()
      |> progress(50)
      |> Map.get("image_url", nil)
      |> progress(75)

    # Attempt to download and install the image
    try do
      with :ok <- UpdateSupport.install_update(url_or_nil) do
        progress(nil, 100)
        FarmbotCeleryScript.SysCalls.reboot()
      else
        {:error, error} -> terminate(error)
        error -> terminate(error)
      end
    after
      # If anything crashes, be sure to clean up artifacts
      # and progress bars.
      progress(nil, 100)
    end

    :ok
  end

  def terminate(error) do
    FarmbotCore.Logger.debug(3, "Upgrade halted: #{inspect(error)}")
  end

  def progress(passthru, 100) do
    set_progress(passthru, %Percent{percent: 100, status: "complete"})
  end

  def progress(passthru, percent) do
    set_progress(passthru, %Percent{percent: percent})
  end

  def set_progress(passthru, percent) do
    if Process.whereis(BotState) do
      BotState.set_job_progress("FBOS_OTA", percent)
    end

    passthru
  end
end
