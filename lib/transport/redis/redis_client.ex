defmodule Farmbot.Transport.Redis do
  @moduledoc """
    Interacts with teh redis db
  """
  use GenStage
  require Logger

  @doc """
    Starts a stage for a Redis
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: GenStage.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    {:ok, redis} = Redis.Client.start_link
    Process.link(redis)
    {:consumer, redis, subscribe_to: [Farmbot.Transport]}
  end

  def handle_info({_from, {:status, stuff}}, redis) do
    Redis.Client.input_value(redis, "BOT_STATUS", stuff)
    {:noreply, [], redis}
  end

  def handle_info(_event, redis) do
    # IO.inspect event
    {:noreply, [], redis}
  end
end
