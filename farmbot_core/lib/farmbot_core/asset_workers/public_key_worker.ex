defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.PublicKey do
  alias FarmbotCore.Asset.PublicKey
  use GenServer

  def tracks_changes?(%PublicKey{}), do: false

  def preload(%PublicKey{}), do: []

  def start_link(%PublicKey{} = public_key, _args) do
    GenServer.start_link(__MODULE__, %PublicKey{} = public_key)
  end

  def init(%PublicKey{} = public_key) do
    {:ok, %PublicKey{} = public_key, 0}
  end

  def handle_info(:timeout, %PublicKey{} = public_key) do
    {:noreply, public_key}
  end
end
