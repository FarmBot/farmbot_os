defmodule Farmbot.Target.UpdateHandler do
  @moduledoc "Handles prep and post OTA update."

  @behaviour Farmbot.System.UpdateHandler
  use Farmbot.Logger

  # Update Handler callbacks

  def apply_firmware(fw_file_path) do
    {meta_bin, 0} = System.cmd("fwup", ~w"-i #{fw_file_path} -m")
    meta_bin
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, "="))
    |> Map.new(fn([key, val]) ->
      {key, val |> String.trim_leading("\"") |> String.trim_trailing("\"")}
    end)
    |> log_meta()

    Nerves.Firmware.upgrade_and_finalize(fw_file_path)
  end

  defp log_meta(meta_map) do
    target = "target: #{meta_map["meta-platform"]}"
    product = "product: #{meta_map["meta-product"]}"
    version = "version: #{meta_map["meta-version"]}"
    create_time = "created: #{meta_map["meta-creation-date"]}"
    msg = """
    Applying Firmware:
    #{create_time}
    #{target}
    #{product}
    #{version}
    """
    Logger.debug 1, msg
  end

  def before_update, do: :ok

  def post_update do
    alias Farmbot.Firmware.UartHandler.Update
    hw = Farmbot.System.ConfigStorage.get_config_value(:string, "settings", "firmware_hardware")
    is_beta? = Farmbot.System.ConfigStorage.get_config_value(:string, "settings", "currently_on_beta")
    if is_beta? do
      Logger.debug 1, "Forcing beta image arduino firmware flash."
      Update.force_update_firmware(hw)
    else
      Update.maybe_update_firmware(hw)
    end
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
