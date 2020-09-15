defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger
  alias FarmbotOS.UpdateSupport

  def check_update() do
    # Try to find the upgrade image URL (might be `nil`)
    url_or_nil =
      UpdateSupport.get_target()
      |> UpdateSupport.download_meta_data()
      |> Map.get("image_url", nil)

    with :ok <- UpdateSupport.install_update(url_or_nil) do
      FarmbotCeleryScript.SysCalls.reboot()
    else
      {:error, error} -> terminate(error)
      error -> terminate(error)
    end
  end

  def terminate(error) do
    FarmbotCore.Logger.debug(3, "Upgrade halted: #{inspect(error)}")
    {:error, error}
  end
end
