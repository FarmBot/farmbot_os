defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Private.Enigma do
  alias FarmbotCore.Asset.Private.Enigma
  alias FarmbotCore.BotState
  use GenServer
  @error_retry_ms 10_000

  def preload(%Enigma{}), do: []

  def start_link(%Enigma{} = enigma, _args) do
    GenServer.start_link(__MODULE__, %Enigma{} = enigma)
  end

  def init(%Enigma{} = enigma) do
    BotState.add_enigma(enigma)
    {:ok, %Enigma{} = enigma, 0}
  end

  def terminate(_, enigma) do
    BotState.clear_enigma(enigma)
    FarmbotCore.EnigmaHandler.handle_down(enigma)
  end

  def handle_info(:timeout, %Enigma{} = enigma) do
    # Handle enigma and block stuff.
    case FarmbotCore.EnigmaHandler.handle_up(enigma) do
     {:error, _} -> {:noreply, enigma, @error_retry_ms}
     :ok -> {:stop, :normal, enigma}
    end
  end
end
