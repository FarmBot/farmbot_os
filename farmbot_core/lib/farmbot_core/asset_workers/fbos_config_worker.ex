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
  import FarmbotFirmware.PackageUtils, only: [package_to_string: 1]

  @firmware_flash_attempt_threshold Application.get_env(:farmbot_core, __MODULE__)[:firmware_flash_attempt_threshold]
  @firmware_flash_attempt_threshold || Mix.raise """
  Firmware open attempt threshold not configured:

  config :farmbot_core, #{__MODULE__}, [
    firmware_flash_attempt_threshold: :infinity
  ]
  """

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
    end
    state = %{
      fbos_config: fbos_config, 
      firmware_flash_attempts: 0, 
      firmware_flash_attempt_threshold: @firmware_flash_attempt_threshold
    }
    {:ok, state, 0}
  end

  @impl GenServer
  def handle_info({:step_complete, _, :ok}, state) do
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
    {:noreply, state}
  end

  def handle_info({:step_complete, _, {:error, reason}}, %{firmware_flash_attempts: tries, firmware_flash_attempt_threshold: thresh} = state)
  when tries >= thresh do
    FarmbotCore.Logger.error 1, """
    Failed flashing firmware: #{reason} 
    Tried #{tries} times. Not retrying
    """
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    {:noreply, %{state | firmware_flash_attempts: 0}}
  end

  def handle_info({:step_complete, _, {:error, reason}}, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    FarmbotCore.Logger.error 1, """
    Error flashing firmware: #{reason} 
    Trying again in 5 seconds
    """
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", true)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    Process.sleep(5000)
    _ = maybe_flash_firmware(state, fbos_config.firmware_hardware, fbos_config.firmware_hardware)
    {:noreply, %{state | firmware_flash_attempts: state.firmware_flash_attempts + 1}}
  end

  def handle_info(:timeout, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    FarmbotCore.Logger.debug 3, "Got initial fbos config"
    set_config_to_state(fbos_config)
    _ = maybe_flash_firmware(state, fbos_config.firmware_hardware, fbos_config.firmware_hardware)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:new_data, new_fbos_config}, %{fbos_config: %FbosConfig{} = old_fbos_config} = state) do
    _ = set_config_to_state(new_fbos_config, old_fbos_config)
    _ = maybe_flash_firmware(state, new_fbos_config.firmware_hardware, old_fbos_config.firmware_hardware)
    {:noreply, %{state | fbos_config: new_fbos_config}}
  end

  def maybe_flash_firmware(_state, "none", _old_hardware) do
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
    :ok
  end

  def maybe_flash_firmware(_state, nil, _old_hardware) do
    FarmbotCore.Logger.warn 1, "Firmware hardware unset. Not flashing"
    :ok
  end

  def maybe_flash_firmware(_state, new_hardware, old_hardware) do
    force? = Config.get_config_value(:bool, "settings", "firmware_needs_flash")
    cond do
      force? ->
        FarmbotCore.Logger.warn 1, "Firmware hardware forced flash"
        Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
        new_hardware
        |> fbos_config_to_flash_firmware_rpc()
        |> FarmbotCeleryScript.execute(make_ref())
      
      new_hardware != old_hardware ->
        FarmbotCore.Logger.warn 1, "Firmware hardware change from #{package_to_string(old_hardware)} to #{package_to_string(new_hardware)}"
        new_hardware
        |> fbos_config_to_flash_firmware_rpc()
        |> FarmbotCeleryScript.execute(make_ref())

      true ->
        # Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
        :ok
    end
  end

  def set_config_to_state(new_fbos_config, old_fbos_config) do
    interesting_params = [
      :arduino_debug_messages,
      :firmware_input_log,
      :firmware_output_log,
      :auto_sync,
      :beta_opt_in,
      :disable_factory_reset,
      :network_not_found_timer,
      :os_auto_update,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log,
    ]
    new_interesting_fbos_config = Map.take(new_fbos_config, interesting_params) |> MapSet.new()
    old_interesting_fbos_config = Map.take(old_fbos_config, interesting_params) |> MapSet.new()
    difference = MapSet.difference(new_interesting_fbos_config, old_interesting_fbos_config)
    Enum.each(difference, fn
      {:arduino_debug_messages, bool} ->
        FarmbotCore.Logger.success 1, "Set arduino debug messages to #{bool}"

      {:firmware_input_log, bool} ->
        FarmbotCore.Logger.success 1, "Set arduino input logs to #{bool}"

      {:firmware_output_log, bool} ->
        FarmbotCore.Logger.success 1, "Set arduino output logs to #{bool}"

      {:auto_sync, bool} ->
        FarmbotCore.Logger.success 1, "Set auto sync to #{bool}"

      {:beta_opt_in, true} ->
        FarmbotCore.Logger.success 1, "Opting into beta updates"

      {:beta_opt_in, false} ->
        FarmbotCore.Logger.success 1, "Opting out of beta updates"

      {:os_auto_update, bool} ->
        FarmbotCore.Logger.success 1, "Set OS auto update to #{bool}"

      {:disable_factory_reset, bool} ->
        FarmbotCore.Logger.success 1, "Set disable factory reset to #{bool}"

      {:network_not_found_timer, seconds} ->
        FarmbotCore.Logger.success 1, "Set connection attempt period to #{seconds}"

      {:sequence_body_log, bool} ->
        FarmbotCore.Logger.success 1, "Set sequence step log messages to #{bool}"

      {:sequence_complete_log, bool} ->
        FarmbotCore.Logger.success 1, "Set sequence complete log messages to #{bool}"

      {:sequence_init_log, bool} ->
        FarmbotCore.Logger.success 1, "Set sequence init log messages to #{bool}"

      {param, value} ->
        FarmbotCore.Logger.success 1, "Set #{param} to #{value}"
    end)
    set_config_to_state(new_fbos_config)
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

  def fbos_config_to_flash_firmware_rpc(firmware_hardware) do
    AST.Factory.new()
    |> AST.Factory.rpc_request("FbosConfig")
    |> AST.Factory.flash_firmware(firmware_hardware)
  end
end
