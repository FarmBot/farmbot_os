defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Private.Enigma do
  alias FarmbotCore.Asset.Private.Enigma
  alias FarmbotCore.BotState
  use GenServer

  def preload(%Enigma{}), do: []

  def start_link(%Enigma{} = enigma, _args) do
    GenServer.start_link(__MODULE__, %Enigma{} = enigma)
  end

  def init(%Enigma{} = enigma) do
    {:ok, %Enigma{} = enigma, 0}
  end

  def terminate(_, enigma) do
    BotState.clear_enigma(enigma)
  end

  def handle_info(:timeout, %Enigma{} = enigma) do
    BotState.add_enigma(enigma)
    # Handle enigma and block stuff.
    {:noreply, enigma}
  end
end
