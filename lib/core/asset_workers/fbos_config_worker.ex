defimpl FarmbotOS.AssetWorker, for: FarmbotOS.Asset.FbosConfig do
  @moduledoc """
  This asset worker does not get restarted. It instead responds to GenServer
  calls.
  """

  use GenServer
  require Logger
  require FarmbotOS.Logger
  alias FarmbotOS.{Asset.FbosConfig, BotState}

  @impl FarmbotOS.AssetWorker
  def preload(%FbosConfig{}), do: []

  @impl FarmbotOS.AssetWorker
  def tracks_changes?(%FbosConfig{}), do: true

  @impl FarmbotOS.AssetWorker
  def start_link(%FbosConfig{} = fbos_config, _args) do
    GenServer.start_link(__MODULE__, %FbosConfig{} = fbos_config)
  end

  @impl GenServer
  def init(%FbosConfig{} = fbos_config) do
    {:ok, %{fbos_config: fbos_config}}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.debug("!!!UNKNOWN FBOS Config Worker Message: #{inspect(message)}")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:new_data, new_fbos_config},
        %{fbos_config: %FbosConfig{} = old_fbos_config} = state
      ) do
    _ = set_config_to_state(new_fbos_config, old_fbos_config)
    {:noreply, %{state | fbos_config: new_fbos_config}}
  end

  def set_config_to_state(new_fbos_config, old_fbos_config) do
    interesting_params = [
      :network_not_found_timer,
      :os_auto_update,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log,
      :boot_sequence_id
    ]

    new_interesting_fbos_config =
      Map.take(new_fbos_config, interesting_params) |> MapSet.new()

    old_interesting_fbos_config =
      Map.take(old_fbos_config, interesting_params) |> MapSet.new()

    difference =
      MapSet.difference(
        new_interesting_fbos_config,
        old_interesting_fbos_config
      )

    Enum.each(difference, fn
      {:boot_sequence_id, bsid} ->
        if not is_nil(bsid) do
          %{sequence_name: name} =
            FarmbotOS.Celery.SysCallGlue.get_sequence(bsid).meta

          FarmbotOS.Logger.success(
            1,
            "Set boot sequence to #{name}"
          )
        else
          FarmbotOS.Logger.success(
            1,
            "Set boot sequence to None"
          )
        end

      {:os_auto_update, bool} ->
        FarmbotOS.Logger.success(1, "Set OS auto update to #{bool}")

      {:network_not_found_timer, minutes} ->
        FarmbotOS.Logger.success(
          1,
          "Set connection attempt period to #{minutes} minutes"
        )

      {:sequence_body_log, bool} ->
        FarmbotOS.Logger.success(
          1,
          "Set sequence step log messages to #{bool}"
        )

      {:sequence_complete_log, bool} ->
        FarmbotOS.Logger.success(
          1,
          "Set sequence complete log messages to #{bool}"
        )

      {:sequence_init_log, bool} ->
        FarmbotOS.Logger.success(
          1,
          "Set sequence init log messages to #{bool}"
        )

      {param, value} ->
        FarmbotOS.Logger.success(1, "Set #{param} to #{value}")
    end)

    set_config_to_state(new_fbos_config)
  end

  def set_config_to_state(fbos_config) do
    # firmware_hardware is set by FarmbotOS.Firmware.SideEffects
    :ok =
      BotState.set_config_value(
        :network_not_found_timer,
        fbos_config.network_not_found_timer
      )

    :ok = BotState.set_config_value(:os_auto_update, fbos_config.os_auto_update)

    # CeleryScript
    :ok =
      BotState.set_config_value(
        :sequence_body_log,
        fbos_config.sequence_body_log
      )

    :ok =
      BotState.set_config_value(
        :sequence_complete_log,
        fbos_config.sequence_complete_log
      )

    :ok =
      BotState.set_config_value(
        :sequence_init_log,
        fbos_config.sequence_init_log
      )
  end
end
