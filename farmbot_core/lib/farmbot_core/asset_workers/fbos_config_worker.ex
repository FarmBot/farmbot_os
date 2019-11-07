defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FbosConfig do
  @moduledoc """
  This asset worker does not get restarted. It inistead responds to GenServer
  calls.
  """

  use GenServer
  require Logger
  require FarmbotCore.Logger
  alias FarmbotCeleryScript.AST
  alias FarmbotCore.{Asset.FbosConfig, BotState, Config, DepTracker}
  import FarmbotFirmware.PackageUtils, only: [package_to_string: 1]

  @firmware_flash_attempt_threshold Application.get_env(:farmbot_core, __MODULE__)[:firmware_flash_attempt_threshold]
  @firmware_flash_timeout Application.get_env(:farmbot_core, __MODULE__)[:firmware_flash_timeout] || 5000
  @disable_firmware_io_logs_timeout Application.get_env(:farmbot_core, __MODULE__)[:disable_firmware_io_logs_timeout] || 300000
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
    :ok = DepTracker.register_asset(fbos_config, :init)
    if Config.get_config_value(:bool, "settings", "firmware_needs_flash") do
      Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    end
    state = %{
      fbos_config: fbos_config,
      firmware_io_timer: nil,
      firmware_flash_attempts: 0,
      firmware_flash_attempt_threshold: @firmware_flash_attempt_threshold,
      firmware_flash_timeout: @firmware_flash_timeout,
      firmware_flash_in_progress: false
    }
    {:ok, state, 0}
  end

  @impl GenServer
  def handle_info({:step_complete, _, :ok}, state) do
    DepTracker.register_asset(state.fbos_config, :idle)
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
    {:noreply, %{state | firmware_flash_in_progress: false}}
  end

  def handle_info({:step_complete, _, {:error, reason}}, %{firmware_flash_attempts: tries, firmware_flash_attempt_threshold: thresh} = state)
  when tries >= thresh do
    DepTracker.register_asset(state.fbos_config, :idle)
    FarmbotCore.Logger.error 1, """
    Failed flashing firmware: #{reason}
    Tried #{tries} times. Not retrying
    """
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", false)
    {:noreply, %{state | firmware_flash_attempts: 0, firmware_flash_in_progress: false}}
  end

  def handle_info({:step_complete, _, {:error, reason}}, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    DepTracker.register_asset(fbos_config, :flash_firmware)
    Config.update_config_value(:bool, "settings", "firmware_needs_flash", true)
    Config.update_config_value(:bool, "settings", "firmware_needs_open", false)

    firmware_flash_timeout = state.firmware_flash_timeout
    firmware_flash_attempts = state.firmware_flash_attempts

    new_state = %{
      state |
      firmware_flash_attempts: firmware_flash_attempts + 1,
      firmware_flash_timeout: @firmware_flash_timeout * (firmware_flash_attempts + 1),
      firmware_flash_in_progress: false
    }
    FarmbotCore.Logger.error 1, """
    Error flashing firmware: #{reason}
    Trying again in #{state.firmware_flash_timeout / 1000} seconds
    """
    Process.send_after(self(), {:maybe_flash_firmware, fbos_config}, firmware_flash_timeout)
    {:noreply, new_state}
  end

  def handle_info(:timeout, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    FarmbotCore.Logger.debug 3, "Got initial fbos config"
    set_config_to_state(fbos_config)
    send self(), {:maybe_flash_firmware, fbos_config}
    send self(), {:maybe_start_io_log_timer, fbos_config}
    {:noreply, state}
  end

  def handle_info({:maybe_flash_firmware, old_fbos_config}, %{fbos_config: %FbosConfig{} = fbos_config} = state) do
    unless state.firmware_flash_in_progress do
      _ = maybe_flash_firmware(state, fbos_config.firmware_hardware, old_fbos_config.firmware_hardware)
    end
    {:noreply, state}
  end

  def handle_info({:maybe_start_io_log_timer, old_fbos_config}, %{fbos_config: fbos_config, firmware_io_timer: nil} = state) do
    out_logs = {old_fbos_config.firmware_output_log, fbos_config.firmware_output_log}
    in_logs = {old_fbos_config.firmware_input_log, fbos_config.firmware_input_log}
    # if either of the log types were enabled, start a timer
    recently_enabled? = match?({_, true}, out_logs) || match?({_, true}, in_logs)
    # if both of the log types are disabled, cancel the timer
    recently_disabled? = match?({_, false}, out_logs) && match?({_, false}, in_logs)
    cond do
      recently_enabled? ->
        FarmbotCore.Logger.info 2, "Firmware logs will be disabled after 5 minutes"
        firmware_io_timer = Process.send_after(self(), :disable_firmware_io_logs, @disable_firmware_io_logs_timeout)
        {:noreply, %{state | firmware_io_timer: firmware_io_timer}}
      recently_disabled? ->
        state.firmware_io_timer && Process.cancel_timer(state.firmware_io_timer)
        {:noreply, %{state | firmware_io_timer: nil}}
      true ->
        {:noreply, state}
    end
  end

  # the timer is already started
  def handle_info({:maybe_start_io_log_timer, _}, state) do
    {:noreply, state}
  end

  def handle_info(:disable_firmware_io_logs, state) do
    new_fbos_config = FarmbotCore.Asset.update_fbos_config!(state.fbos_config, %{
      firmware_output_log: false,
      firmware_input_log: false
    })
    _ = FarmbotCore.Asset.Private.mark_dirty!(new_fbos_config)
    FarmbotCore.Logger.info 2, "Automatically disabling firmware IO logs (5 minutes have elapsed)"
    {:noreply, %{state | fbos_config: new_fbos_config, firmware_io_timer: nil}}
  end

  def handle_info(:bootup_sequence, state) do
    DepTracker.register_asset(state.fbos_config, :idle)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:new_data, new_fbos_config}, %{fbos_config: %FbosConfig{} = old_fbos_config} = state) do
    _ = set_config_to_state(new_fbos_config, old_fbos_config)
    send self(), {:maybe_flash_firmware, old_fbos_config}
    send self(), {:maybe_start_io_log_timer, old_fbos_config}
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

  def maybe_flash_firmware(state, new_hardware, old_hardware) do
    force? = Config.get_config_value(:bool, "settings", "firmware_needs_flash")
    cond do
      force? ->
        DepTracker.register_asset(state.fbos_config, :firmware_flash)
        FarmbotCore.Logger.warn 1, "Firmware hardware forced flash"
        Config.update_config_value(:bool, "settings", "firmware_needs_flash", false)
        new_hardware
        |> fbos_config_to_flash_firmware_rpc()
        |> FarmbotCeleryScript.execute(make_ref())

      new_hardware != old_hardware ->
        DepTracker.register_asset(state.fbos_config, :firmware_flash)
        FarmbotCore.Logger.warn 1, "Firmware hardware change from #{package_to_string(old_hardware)} to #{package_to_string(new_hardware)}"
        new_hardware
        |> fbos_config_to_flash_firmware_rpc()
        |> FarmbotCeleryScript.execute(make_ref())

      true ->
        # Config.update_config_value(:bool, "settings", "firmware_needs_open", true)
        send self(), :bootup_sequence
        :ok
    end
  end

  def set_config_to_state(new_fbos_config, old_fbos_config) do
    interesting_params = [
      :arduino_debug_messages,
      :firmware_input_log,
      :firmware_output_log,
      :firmware_debug_log,
      :auto_sync,
      :beta_opt_in,
      :disable_factory_reset,
      :network_not_found_timer,
      :os_auto_update,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log,
      :update_channel
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

      {:firmware_debug_log, bool} ->
        FarmbotCore.Logger.success 1, "Set arduino debug messages to #{bool}"

      {:auto_sync, bool} ->
        FarmbotCore.Logger.success 1, "Set auto sync to #{bool}"

      {:beta_opt_in, true} ->
        FarmbotCore.Logger.success 1, "Opting into beta updates"

      {:beta_opt_in, false} ->
        FarmbotCore.Logger.success 1, "Opting out of beta updates"

      {:update_channel, channel} ->
        FarmbotCore.Logger.success 1, "Set OS update channel to #{channel}"

      {:os_auto_update, bool} ->
        FarmbotCore.Logger.success 1, "Set OS auto update to #{bool}"

      {:disable_factory_reset, bool} ->
        FarmbotCore.Logger.success 1, "Set automatic factory reset to #{!bool}"

      {:network_not_found_timer, minutes} ->
        FarmbotCore.Logger.success 1, "Set connection attempt period to #{minutes} minutes"

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
    :ok = BotState.set_config_value(:firmware_debug_log, fbos_config.firmware_debug_log)

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
    |> AST.Factory.rpc_request("fbos_config.flash_firmware")
    |> AST.Factory.flash_firmware(firmware_hardware)
  end
end
