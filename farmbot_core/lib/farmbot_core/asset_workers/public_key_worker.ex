defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.PublicKey do
  alias FarmbotCore.Asset.PublicKey
  use GenServer

  @ssh_handler Application.get_env(:farmbot_core, __MODULE__)[:ssh_handler]
  @ssh_handler ||
    Mix.raise("""
      config :farmbot_core, #{__MODULE__}, 
        ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler
    """)

  def tracks_changes?(%PublicKey{}), do: false

  def preload(%PublicKey{}), do: []

  def start_link(%PublicKey{} = public_key, _args) do
    GenServer.start_link(__MODULE__, %PublicKey{} = public_key)
  end

  def init(%PublicKey{} = public_key) do
    {:ok, %{public_key: public_key}, 0}
  end

  def handle_info(:timeout, state) do
    if ssh_handler().ready?() do
      ssh_handler().add_key(state.public_key)
      {:noreply, state}
    else
      {:noreply, state, 5000}
    end
  end

  def ssh_handler() do
    Application.get_env(:farmbot_core, __MODULE__)[:ssh_handler]
  end
end
