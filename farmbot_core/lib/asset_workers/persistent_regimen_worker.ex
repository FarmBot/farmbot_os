defimpl Farmbot.AssetWorker, for: Farmbot.Asset.PersistentRegimen do
  use GenServer
  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3]

  def start_link(persistent_regimen) do
    GenServer.start_link(__MODULE__, [persistent_regimen])
  end

  def init([persistent_regimen]) do
    {:ok, persistent_regimen}
  end
end
