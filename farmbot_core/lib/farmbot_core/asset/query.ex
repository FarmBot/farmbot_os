defmodule FarmbotCore.Asset.Query do
  alias FarmbotCore.Asset
  @callback auto_sync?() :: boolean()
  def auto_sync?() do
    Asset.fbos_config().auto_sync
  end
end
