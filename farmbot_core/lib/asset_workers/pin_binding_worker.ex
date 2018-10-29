defimpl Farmbot.AssetWorker, for: Farmbot.Asset.PinBinding do
  use GenServer

  def start_link(pin_binding) do
    GenServer.start_link(__MODULE__, [pin_binding])
  end

  def init([pin_binding]) do
    {:ok, pin_binding}
  end
end
