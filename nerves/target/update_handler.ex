defmodule Farmbot.Target.UpdateHandler do
  @moduledoc "Handles prep and post OTA update."

  @behaviour Farmbot.System.UpdateHandler
  use Farmbot.Logger

  # Update Handler callbacks

  def apply_firmware(file_path) do
    Nerves.Firmware.upgrade_and_finalize(file_path)
  end

  def before_update do
    :ok
  end

  def post_update do
    Farmbot.Firmware.UartHandler.Update.maybe_update_firmware()
    :ok
  end
end
