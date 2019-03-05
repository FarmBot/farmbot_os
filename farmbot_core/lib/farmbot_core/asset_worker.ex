defprotocol FarmbotCore.AssetWorker do
  @doc "List of relational resources that need to be preloaded."
  def preload(asset)

  @doc "GenServer childspec callback."
  def start_link(asset, args \\ [])
end
