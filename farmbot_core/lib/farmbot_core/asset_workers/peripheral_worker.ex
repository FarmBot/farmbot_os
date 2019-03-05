defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Peripheral do
  use GenServer
  require FarmbotCore.Logger

  alias FarmbotCore.{Asset.Peripheral}
  alias FarmbotCeleryScript.{AST, Scheduler}

  @retry_ms 1_000

  @impl true
  def preload(%Peripheral{}), do: []

  @impl true
  def start_link(peripheral, _args) do
    GenServer.start_link(__MODULE__, peripheral)
  end

  @impl true
  def init(peripheral) do
    {:ok, %{peripheral: peripheral, scheduled_ref: nil, errors: 0}, 0}
  end

  @impl true
  def handle_info(:timeout, %{peripheral: peripheral} = state) do
    FarmbotCore.Logger.busy(2, "Read peripheral: #{peripheral.label}")
    rpc = peripheral_to_rpc(peripheral)
    {:ok, ref} = Scheduler.schedule(rpc)
    {:noreply, %{state | peripheral: peripheral, scheduled_ref: ref}}
  end

  def handle_info({Scheduler, ref, :ok}, %{peripheral: peripheral, scheduled_ref: ref} = state) do
    FarmbotCore.Logger.success(2, "Read peripheral: #{peripheral.label} ok")
    {:noreply, state, :hibernate}
  end

  def handle_info({Scheduler, ref, {:error, reason}}, %{peripheral: peripheral, scheduled_ref: ref, errors: 5} = state) do
    FarmbotCore.Logger.error(1, "Read peripheral: #{peripheral.label} error: #{reason} errors=5 not trying again.")
    {:noreply, state, :hibernate}
  end

  def handle_info({Scheduler, ref, {:error, reason}}, %{peripheral: peripheral, scheduled_ref: ref} = state) do
    FarmbotCore.Logger.error(1, "Read peripheral: #{peripheral.label} error: #{reason} errors=#{state.errors}")
    {:noreply, %{state | scheduled_ref: nil, errors: state.errors + 1}, @retry_ms}
  end

  def peripheral_to_rpc(peripheral) do
    AST.Factory.new()
    |> AST.Factory.rpc_request(peripheral.local_id)
    |> AST.Factory.read_pin(peripheral.pin, peripheral.mode)
  end
end
