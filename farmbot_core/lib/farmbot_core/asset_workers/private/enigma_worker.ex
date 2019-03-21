defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.Private.Enigma do
  alias FarmbotCore.Asset.Private.Enigma
  alias FarmbotCore.BotState
  use GenServer
  require Logger

  @error_retry_time_ms Application.get_env(:farmbot_core, __MODULE__)[:error_retry_time_ms]
  @error_retry_time_ms ||
    Mix.raise("""
    config :farmbot_core, #{__MODULE__}, error_retry_time_ms: 10_000
    """)

  def preload(%Enigma{}), do: []

  def start_link(%Enigma{} = enigma, _args) do
    GenServer.start_link(__MODULE__, enigma)
  end

  def init(%Enigma{} = enigma) do
    {:ok, %{enigma: enigma, dead: false}, 0}
  end

  def terminate(_reason, state) do
    finish(state)
  end

  def handle_info(:timeout, %{dead: true} = state) do
    {:noreply, state, :hibernate}
  end

  def handle_info(:timeout, %{enigma: enigma, dead: false} = state) do
    BotState.add_enigma(enigma)
    # Handle enigma and block stuff.
    case FarmbotCore.EnigmaHandler.handle_up(enigma) do
      {:error, _} ->
        {:noreply, state, @error_retry_time_ms}

      :ok ->
        {:noreply, finish(%{state | dead: true})}
    end
  end

  def finish(state) do
    Logger.info "Enigma #{inspect(state.enigma)} moving to finished state"
    BotState.clear_enigma(state.enigma)
    result = FarmbotCore.EnigmaHandler.handle_down(state.enigma)
    Logger.info "Result of handle_down/1: #{inspect(result)}"
    state
  end
end
