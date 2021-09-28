defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Peripheral do
  use GenServer
  require Logger

  alias FarmbotCore.{Asset.Peripheral, BotState}
  alias FarmbotCore.Celery.AST

  @retry_ms 1_000

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
    state =  %{peripheral: peripheral, errors: 0, fw_idle: idle || false, fw_version: fw_version}
    send self(), :timeout
    {:ok, state}
  end

  @impl true
  def handle_info(:timeout, %{fw_version: nil} = state) do
    # Logger.debug("Not reading peripheral. Firmware not started.")
    Process.send_after(self(), :timeout, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:timeout, %{fw_version: "8.0.0.S.stub"} = state) do
    {:noreply, state}
  end

  def handle_info(:timeout, %{fw_idle: false} = state) do
    # Logger.debug("Not reading peripheral. Firmware not idle.")
    Process.send_after(self(), :timeout, @retry_ms)
    {:noreply, state}
  end

  def handle_info(:timeout, %{peripheral: peripheral, errors: errors} = state) do
    Logger.debug("Read peripheral: #{peripheral.label}")
    rpc = peripheral_to_rpc(peripheral)
    case FarmbotCore.Celery.execute(rpc, make_ref()) do
      :ok ->
        Logger.debug("Read peripheral: #{peripheral.label} ok")
        {:noreply, state}

      {:error, reason} when errors < 5 ->
        Logger.error("Read peripheral: #{peripheral.label} error: #{reason} errors=#{state.errors}")
        Process.send_after(self(), :timeout, @retry_ms)
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

  def handle_info({BotState, _}, state) do
    {:noreply, state}
  end

  def handle_info({:csvm_done, _, _}, state) do
    {:noreply, state}
  end

  def peripheral_to_rpc(peripheral) do
    AST.Factory.new()
    |> AST.Factory.rpc_request(peripheral.local_id)
    |> AST.Factory.set_pin_io_mode(peripheral.pin, "output")
    |> AST.Factory.read_pin(peripheral.pin, peripheral.mode)
  end
end
