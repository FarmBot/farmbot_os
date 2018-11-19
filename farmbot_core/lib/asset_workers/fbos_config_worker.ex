defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FbosConfig do
  use GenServer
  require Logger

  alias Farmbot.Asset.FbosConfig
  import Farmbot.Config, only: [update_config_value: 4]

  def preload(%FbosConfig{}), do: []

  def start_link(%FbosConfig{} = fbos_config, _args) do
    GenServer.start_link(__MODULE__, %FbosConfig{} = fbos_config)
  end

  def init(%FbosConfig{} = fbos_config) do
    {:ok, %FbosConfig{} = fbos_config, 0}
  end

  def handle_info(:timeout, %FbosConfig{} = fbos_config) do
    maybe_reinit_firmware(fbos_config)
    bool("arduino_debug_messages", fbos_config.arduino_debug_messages)
    bool("auto_sync", fbos_config.auto_sync)
    bool("beta_opt_in", fbos_config.beta_opt_in)
    bool("disable_factory_reset", fbos_config.disable_factory_reset)
    string("firmware_hardware", fbos_config.firmware_hardware)
    bool("firmware_input_log", fbos_config.firmware_input_log)
    bool("firmware_output_log", fbos_config.firmware_output_log)
    float("network_not_found_timer", fbos_config.network_not_found_timer)
    bool("os_auto_update", fbos_config.os_auto_update)
    bool("sequence_body_log", fbos_config.sequence_body_log)
    bool("sequence_complete_log", fbos_config.sequence_complete_log)
    bool("sequence_init_log", fbos_config.sequence_init_log)
    {:noreply, fbos_config}
  end

  defp bool(key, val) do
    update_config_value(:bool, "settings", key, val)
    :ok = Farmbot.BotState.set_config_value(key, val)
  end

  defp string(key, val) do
    update_config_value(:string, "settings", key, val)
    :ok = Farmbot.BotState.set_config_value(key, val)
  end

  defp float(_key, nil) do
    :ok
  end

  defp float(key, val) do
    update_config_value(:float, "settings", key, val / 1)
    :ok = Farmbot.BotState.set_config_value(key, val)
  end

  defp maybe_reinit_firmware(%FbosConfig{firmware_hardware: nil}) do
    :ok
  end

  defp maybe_reinit_firmware(%FbosConfig{firmware_path: nil}) do
    :ok
  end

  defp maybe_reinit_firmware(%FbosConfig{}) do
    alias Farmbot.Firmware
    alias Farmbot.Core.FirmwareSupervisor

    if is_nil(Process.whereis(Firmware)) do
      Logger.warn("Starting Farmbot firmware")
      FirmwareSupervisor.reinitialize()
    end
  end
end
