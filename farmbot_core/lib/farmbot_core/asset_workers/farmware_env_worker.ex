defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FarmwareEnv do
  use GenServer

  alias FarmbotCore.{Asset.FarmwareEnv, BotState}

  def preload(%FarmwareEnv{}), do: []

  def start_link(%FarmwareEnv{} = env, _args) do
    GenServer.start_link(__MODULE__, env)
  end

  def init(%FarmwareEnv{} = env) do
    {:ok, env, 0}
  end

  def handle_info(:timeout, %FarmwareEnv{key: key, value: value} = env) do
    :ok = BotState.set_user_env(key, value)
    {:noreply, env, :hibernate}
  end
end
