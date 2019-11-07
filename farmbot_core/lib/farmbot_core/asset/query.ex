defmodule FarmbotCore.Asset.Query do
  @moduledoc """
  Get data from the database
  """
  
  alias FarmbotCore.Asset

  @callback auto_sync?() :: boolean()

  @callback first_sync?() :: boolean()

  @doc "Returns the configuration value for auto_sync"
  def auto_sync?() do
    Asset.fbos_config().auto_sync
  end

  @doc "Checks if initial syncing is still required"
  def first_sync?() do
    is_nil(Asset.fbos_config().id)
  end
end
