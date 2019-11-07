defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Peripheral do
  use GenServer
  require Logger
  require FarmbotCore.Logger

  alias FarmbotCore.{Asset.FbosConfig, Asset.Peripheral, BotState, DepTracker}
  alias FarmbotCeleryScript.AST

  @retry_ms 1_000

  @unacceptable_fbos_config_statuses [
    nil,
    :init,
    :firmware_flash,
    :bootup_sequence,
  ]

  @impl true
  def preload(%Peripheral{}), do: []

  @impl true
  def tracks_changes?(%Peripheral{}), do: false

  @impl true
  def start_link(peripheral, _args) do
    GenServer.start_link(__MODULE__, peripheral)
  end

  @impl true
  def init(peripheral) do
    %{
      informational_settings: %{
        idle: idle, 
        firmware_version: fw_version,
        firmware_configured: fw_configured
      }
    } = BotState.subscribe()
    state =  %{
      peripheral: peripheral, 
      errors: 0, 
      fw_idle: idle || false, 
      fw_version: fw_version,
      fw_configured: fw_configured || false, 
      fbos_config_status: nil
    }
    :ok = DepTracker.subscribe_asset(FbosConfig)
    send self(), :try_read_peripheral
    {:ok, state}
  end

  @impl true
  def handle_info({DepTracker, {FbosConfig, _}, _old, status}, state) do
    {:noreply, %{state | fbos_config_status: status}}
  end

  def handle_info(:try_read_peripheral, %{fbos_config_status: fbos_config_status} = state)
  when fbos_config_status in @unacceptable_fbos_config_statuses do
    # Logger.debug("Not reading peripheral. fbos_config not in acceptable state: #{fbos_config_status}")
    Process.send_after(self(), :try_read_peripheral, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:try_read_peripheral, %{fbos_config_status: :bootup_sequence} = state) do
    # Logger.debug("Not reading peripheral. Bootup sequence not complete")
    Process.send_after(self(), :try_read_peripheral, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:try_read_peripheral, %{fw_version: nil} = state) do
    # Logger.debug("Not reading peripheral. Firmware not booted.")
    Process.send_after(self(), :try_read_peripheral, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:try_read_peripheral, %{fw_version: "none"} = state) do
    # Logger.debug("Not reading peripheral. Firmware not booted.")
    Process.send_after(self(), :try_read_peripheral, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:try_read_peripheral, %{fw_configured: false} = state) do
    # Logger.debug("Not reading peripheral. Firmware not configured.")
    Process.send_after(self(), :try_read_peripheral, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:try_read_peripheral, %{fw_idle: false} = state) do
    # Logger.debug("Not reading peripheral. Firmware not idle.")
    Process.send_after(self(), :try_read_peripheral, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:try_read_peripheral, %{peripheral: peripheral, errors: errors} = state) do
    Logger.debug("Read peripheral: #{peripheral.label}")
    rpc = peripheral_to_rpc(peripheral)
    case FarmbotCeleryScript.execute(rpc, make_ref()) do
      :ok -> 
        Logger.debug("Read peripheral: #{peripheral.label} ok")
        {:noreply, state}
      
      {:error, reason} when errors < 5 -> 
        Logger.error("Read peripheral: #{peripheral.label} error: #{reason} errors=#{state.errors} status=#{state.fbos_config_status}")
        Process.send_after(self(), :try_read_peripheral, @retry_ms)
        {:noreply, %{state | errors: state.errors + 1}}
      
      {:error, reason} when errors == 5 ->
        Logger.error("Read peripheral: #{peripheral.label} error: #{reason} errors=5 not trying again.")
        {:noreply, state}
    end
  end

  def handle_info({BotState, %{changes: %{informational_settings: %{changes: %{idle: idle}}}}}, state) do
    {:noreply, %{state | fw_idle: idle}}
  end

  def handle_info({BotState, %{changes: %{informational_settings: %{changes: %{firmware_version: fw_version}}}}}, state) do
    {:noreply, %{state | fw_version: fw_version}}
  end

  def handle_info({BotState, %{changes: %{informational_settings: %{changes: %{firmware_configured: fw_configured}}}}}, state) do
    # this should really be fixed upstream not to dispatch if version is none.
    if state.fw_version == "none" do
      {:noreply, state}
    else
      {:noreply, %{state | fw_configured: fw_configured}}
    end
  end

  def handle_info({BotState, _}, state) do
    {:noreply, state}
  end

  def handle_info({:step_complete, _, _}, state) do
    {:noreply, state}
  end

  def peripheral_to_rpc(peripheral) do
    AST.Factory.new()
    |> AST.Factory.rpc_request("peripheral." <> peripheral.local_id)
    |> AST.Factory.set_pin_io_mode(peripheral.pin, "output")
    |> AST.Factory.read_pin(peripheral.pin, peripheral.mode)
  end
end
