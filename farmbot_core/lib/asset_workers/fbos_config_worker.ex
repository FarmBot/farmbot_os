defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FbosConfig do
  use GenServer
  require Logger

  alias Farmbot.Asset.FbosConfig
  alias Farmbot.BotState

  def preload(%FbosConfig{}), do: []

  def start_link(%FbosConfig{} = fbos_config, _args) do
    GenServer.start_link(__MODULE__, %FbosConfig{} = fbos_config)
  end

  def init(%FbosConfig{} = fbos_config) do
    {:ok, %FbosConfig{} = fbos_config, 0}
  end

  def handle_info(:timeout, %FbosConfig{} = fbos_config) do
    :ok = BotState.set_config_value(:arduino_debug_messages, fbos_config.arduino_debug_messages)
    :ok = BotState.set_config_value(:auto_sync, fbos_config.auto_sync)
    :ok = BotState.set_config_value(:beta_opt_in, fbos_config.beta_opt_in)
    :ok = BotState.set_config_value(:disable_factory_reset, fbos_config.disable_factory_reset)
    :ok = BotState.set_config_value(:firmware_hardware, fbos_config.firmware_hardware)
    :ok = BotState.set_config_value(:firmware_input_log, fbos_config.firmware_input_log)
    :ok = BotState.set_config_value(:firmware_output_log, fbos_config.firmware_output_log)
    :ok = BotState.set_config_value(:network_not_found_timer, fbos_config.network_not_found_timer)
    :ok = BotState.set_config_value(:os_auto_update, fbos_config.os_auto_update)
    :ok = BotState.set_config_value(:sequence_body_log, fbos_config.sequence_body_log)
    :ok = BotState.set_config_value(:sequence_complete_log, fbos_config.sequence_complete_log)
    :ok = BotState.set_config_value(:sequence_init_log, fbos_config.sequence_init_log)
    {:noreply, fbos_config}
  end
end
