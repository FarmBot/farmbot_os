defmodule Farmbot.Asset.Registry do
  @moduledoc "Event system for receiving inserts, updates, or deletions of assets."
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end
end
