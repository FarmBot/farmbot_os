defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FarmwareEnv do
  use GenServer

  alias Farmbot.Asset.FarmwareEnv

  def preload(%FarmwareEnv{}), do: []

  def start_link(%FarmwareEnv{} = env, _args) do
    GenServer.start_link(__MODULE__, env)
  end

  def init(%FarmwareEnv{} = env) do
    {:ok, env, 0}
  end

  def handle_info(:timeout, %FarmwareEnv{key: key, value: value} = env) do
    :ok = Farmbot.BotState.set_user_env(key, value)
    {:noreply, env, :hibernate}
  end
end
