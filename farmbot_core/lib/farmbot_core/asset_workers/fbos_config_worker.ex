defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FbosConfig do
  @moduledoc """
  This asset worker does not get restarted. It inistead responds to GenServer
  calls.
  """

  use GenServer
  require Logger
  require FarmbotCore.Logger
  alias FarmbotCeleryScript.AST
  alias FarmbotCore.{Asset.FbosConfig, BotState, Config}

  @impl FarmbotCore.AssetWorker
  def preload(%FbosConfig{}), do: []

  @impl FarmbotCore.AssetWorker
  def tracks_changes?(%FbosConfig{}), do: true

  @impl FarmbotCore.AssetWorker
  def start_link(%FbosConfig{} = fbos_config, _args) do
    GenServer.start_link(__MODULE__, %FbosConfig{} = fbos_config)
  end

  @impl GenServer
  def init(%FbosConfig{} = fbos_config) do
    if Config.get_config_value(:bool, "settings", "firmware_needs_flash") do
      Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    else
      Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
    end
    {:ok, %{fbos_config: fbos_config, firmware_flash_tries: 0}, 0}
  end

  @impl GenServer
  def handle_info({:step_complete, _, :ok}, state) do
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
    {:noreply, state}
  end

  def handle_info({:step_complete, _, {:error, reason}}, %{firmware_flash_tries: tries} = state)
  when tries >= 3 do
    FarmbotCore.Logger.error 1, """
    Failed flashing firmware: #{reason} 
    Tried #{tries} times. Not retrying
    """
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", true)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    {:noreply, %{state | firmware_flash_tries: 0}}
  end

  def handle_info({:step_complete, _, {:error, reason}}, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    FarmbotCore.Logger.error 1, """
    Error flashing firmware: #{reason} 
    Trying again
    """
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", true)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    maybe_flash_firmware(fbos_config, fbos_config)
    {:noreply, %{state | firmware_flash_tries: state.firmware_flash_tries + 1}}
  end

  def handle_info(:timeout, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    FarmbotCore.Logger.debug 3, "Got initial fbos config"
    set_config_to_state(fbos_config)
    maybe_flash_firmware(fbos_config, fbos_config)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:new_data, new_fbos_config}, %{fbos_config: %FbosConfig{} = old_fbos_config} = state) do
    FarmbotCore.Logger.debug 3, "Got new fbos config"
    set_config_to_state(new_fbos_config)
    maybe_flash_firmware(new_fbos_config, old_fbos_config)
    {:noreply, %{state | fbos_config: new_fbos_config}}
  end

  def maybe_flash_firmware(%{firmware_hardware: new_hardware} = new_fbos_config, %{firmware_hardware: old_hardware}) do
    force? = Config.get_config_value(:bool, "settings", "firmware_needs_flash")
    cond do
      new_hardware == nil ->
        FarmbotCore.Logger.warn 1, "Firmware hardware unset. Not flashing"
        :ok
        
      force? ->
        rpc = fbos_config_to_flash_firmware_rpc(new_fbos_config)
        FarmbotCore.Logger.warn 1, "Firmware hardware forced flash"
        Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
        FarmbotCeleryScript.execute(rpc, make_ref())
      
      new_hardware != old_hardware ->
        rpc = fbos_config_to_flash_firmware_rpc(new_fbos_config)
        FarmbotCore.Logger.warn 1, "Firmware hardware change from #{old_hardware} to #{new_hardware} flashing firmware"
        FarmbotCeleryScript.execute(rpc, make_ref())

      true ->
        Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
        :ok
    end
  end

  def set_config_to_state(fbos_config) do
    # firmware
    :ok = BotState.set_config_value(:arduino_debug_messages, fbos_config.arduino_debug_messages)
    :ok = BotState.set_config_value(:firmware_input_log, fbos_config.firmware_input_log)
    :ok = BotState.set_config_value(:firmware_output_log, fbos_config.firmware_output_log)
    # firmware_hardware is set by FarmbotFirmware.SideEffects

    :ok = BotState.set_config_value(:auto_sync, fbos_config.auto_sync)
    :ok = BotState.set_config_value(:beta_opt_in, fbos_config.beta_opt_in)
    :ok = BotState.set_config_value(:disable_factory_reset, fbos_config.disable_factory_reset)
    :ok = BotState.set_config_value(:network_not_found_timer, fbos_config.network_not_found_timer)
    :ok = BotState.set_config_value(:os_auto_update, fbos_config.os_auto_update)

    # CeleryScript
    :ok = BotState.set_config_value(:sequence_body_log, fbos_config.sequence_body_log)
    :ok = BotState.set_config_value(:sequence_complete_log, fbos_config.sequence_complete_log)
    :ok = BotState.set_config_value(:sequence_init_log, fbos_config.sequence_init_log)
  end

  def fbos_config_to_flash_firmware_rpc(fbos_config) do
    AST.Factory.new()
    |> AST.Factory.rpc_request(fbos_config.local_id)
    |> AST.Factory.flash_firmware(fbos_config.firmware_hardware)
  end
end
