defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger

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
    update_progress = UpdateProgress.start_link([])
    # Try to find the upgrade image URL (might be `nil`)
    url_or_nil =
      UpdateSupport.get_target()
      |> UpdateSupport.download_meta_data()
      |> Map.get("image_url", nil)

    with :ok <- UpdateSupport.install_update(url_or_nil) do
      UpdateProgress.set(update_progress, 100)
      FarmbotCeleryScript.SysCalls.reboot()
    else
      {:error, error} -> terminate(error, update_progress)
      error -> terminate(error, update_progress)
    end
  end

  def terminate(error, update_progress) do
    FarmbotCore.Logger.debug(3, "Upgrade halted: #{inspect(error)}")
    UpdateProgress.set(update_progress, 100)
    {:error, error}
  end
end
