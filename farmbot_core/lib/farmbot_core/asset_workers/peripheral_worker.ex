defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Peripheral do
  use GenServer
  require FarmbotCore.Logger

  alias FarmbotCore.{Asset.Peripheral, BotState}
  alias FarmbotCeleryScript.{AST, Scheduler}

  @retry_ms 1_000
  @wrong_fw_versions [nil, "8.0.0.S"]

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
    %{informational_settings: %{idle: idle, firmware_version: fw_version}} = BotState.subscribe()
    state =  %{peripheral: peripheral, scheduled_ref: nil, errors: 0, fw_idle: idle || false, fw_version: fw_version}
    send self(), :timeout
    {:ok, state}
  end

  @impl true
  def handle_info(:timeout, %{fw_version: wrong} = state) when wrong in @wrong_fw_versions do
    FarmbotCore.Logger.debug(3, "Not reading peripheral. Firmware not started.")
    Process.send_after(self(), :timeout, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:timeout, %{fw_idle: false} = state) do
    FarmbotCore.Logger.debug(3, "Not reading peripheral. Firmware not idle.")
    Process.send_after(self(), :timeout, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:timeout, %{peripheral: peripheral} = state) do
    FarmbotCore.Logger.busy(2, "Read peripheral: #{peripheral.label}")
    rpc = peripheral_to_rpc(peripheral)
    {:ok, ref} = Scheduler.schedule(rpc)
    {:noreply, %{state | peripheral: peripheral, scheduled_ref: ref}}
  end

  def handle_info({Scheduler, ref, :ok}, %{peripheral: peripheral, scheduled_ref: ref} = state) do
    FarmbotCore.Logger.success(2, "Read peripheral: #{peripheral.label} ok")
    {:noreply, state}
  end

  def handle_info({Scheduler, ref, {:error, reason}}, %{peripheral: peripheral, scheduled_ref: ref, errors: 5} = state) do
    FarmbotCore.Logger.error(1, "Read peripheral: #{peripheral.label} error: #{reason} errors=5 not trying again.")
    {:noreply, state}
  end

  def handle_info({Scheduler, ref, {:error, reason}}, %{peripheral: peripheral, scheduled_ref: ref} = state) do
    FarmbotCore.Logger.error(1, "Read peripheral: #{peripheral.label} error: #{reason} errors=#{state.errors}")
    Process.send_after(self(), :timeout, @retry_ms)
    {:noreply, %{state | scheduled_ref: nil, errors: state.errors + 1}}
  end

  def handle_info({BotState, %{changes: %{informational_settings: %{changes: %{idle: idle}}}}}, state) do
    {:noreply, %{state | fw_idle: idle}}
  end

  def handle_info({BotState, %{changes: %{informational_settings: %{changes: %{firmware_version: fw_version}}}}}, state) do
    {:noreply, %{state | fw_version: fw_version}}
  end

  def handle_info({BotState, _}, state) do
    {:noreply, state}
  end

  def peripheral_to_rpc(peripheral) do
    AST.Factory.new()
    |> AST.Factory.rpc_request(peripheral.local_id)
    |> AST.Factory.read_pin(peripheral.pin, peripheral.mode)
  end
end
