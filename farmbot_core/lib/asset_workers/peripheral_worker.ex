defimpl Farmbot.AssetWorker, for: Farmbot.Asset.Peripheral do
  use GenServer
  alias Farmbot.Core.CeleryScript
  import Farmbot.CeleryScript.Utils
  require Farmbot.Logger
  @retry_ms 5_000

  def start_link(peripheral) do
    GenServer.start_link(__MODULE__, [peripheral])
  end

  def init([peripheral]) do
    {:ok, peripheral, 0}
  end

  def handle_info(:timeout, peripheral) do
    # Farmbot.Logger.info 2, "Read peripheral: #{peripheral.label}"
    CeleryScript.rpc_request(peripheral_to_rpc(peripheral), &handle_ast(&1, self()))
    {:noreply, peripheral}
  end

  def handle_cast(%{kind: :rpc_ok}, peripheral) do
    Farmbot.Logger.success 2, "Read peripheral: #{peripheral.label} ok"
    {:stop, :normal, peripheral}
  end

  def handle_cast(%{kind: :rpc_error} = rpc, peripheral) do
    Farmbot.Logger.error 1, "Read peripheral: #{peripheral.label} error"
    IO.inspect(rpc, label: "error")
    {:noreply, peripheral, @retry_ms}
  end

  def handle_ast(ast, pid) do
    :ok = GenServer.cast(pid, ast)
  end

  def peripheral_to_rpc(peripheral) do
    ast(:rpc_request, %{label: peripheral.local_id}, [
      ast(
        :read_pin,
        %{
          pin_num: peripheral.pin,
          label: peripheral.label,
          pin_mode: peripheral.mode
        },
        []
      )
    ])
  end
end
