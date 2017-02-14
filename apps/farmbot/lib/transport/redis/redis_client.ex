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
    {:consumer, [], subscribe_to: [Farmbot.Transport]}
  end

  def handle_info({_from, {:status, state}}, state) do
    Redis.Client.input_value("BOT_STATUS", state)
    {:noreply, [], state}
  end

  def handle_info(event, state) do
    {:noreply, [], state}
  end
end
