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
    alias Farmbot.Firmware.UartHandler.Update
    hw = Farmbot.System.ConfigStorage.get_config_value(:string, "settings", "firmware_hardware")
    Update.maybe_update_firmware()
    :ok
  end

  def setup(:prod) do
    file = "#{:code.priv_dir(:farmbot)}/fwup-key.pub"
    Application.put_env(:nerves_firmware, :pub_key_path, file)
    if File.exists?(file), do: :ok, else: {:error, :no_pub_file}
  end

  def setup(_) do
    :ok
  end

  def requires_reboot? do
    !Nerves.Firmware.allow_upgrade?
  end
end
