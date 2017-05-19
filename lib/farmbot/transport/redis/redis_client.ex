defmodule Farmbot.Transport.Redis do
  @moduledoc """
    Interacts with teh redis db
  """
  use GenStage
  require Logger
  alias Farmbot.Context
  @config Application.get_all_env(:farmbot)[:redis]
  @ping_time 5_000
  @save_time 900_000

  @doc """
    Starts a stage for a Redis
  """
  @spec start_link(Context.t, [{atom, any}]) :: {:ok, pid}
  def start_link(context, opts), do: GenStage.start_link(__MODULE__, context, opts)

  def init(%Context{} = _context) do
    {:ok, conn} = Redix.start_link(host: "localhost", port: @config[:port])
    Process.link(conn)
    Process.send_after(self(), :ping, @ping_time)
    Process.send_after(self(), :save, @save_time)
    {:consumer, conn, subscribe_to: [Farmbot.Transport]}
  end

  def handle_info({_from, {:status, stuff}}, redis) do
    Redis.Client.Public.input_value(redis, "BOT_STATUS", stuff)
    {:noreply, [], redis}
  end

  def handle_info(:ping, conn) do
    Redis.Client.Public.send_redis(conn, ["PING"])
    Process.send_after(self(), :ping, @ping_time)
    {:noreply, [], conn}
  end

  def handle_info(:save, conn) do
    Farmbot.System.FS.transaction fn() ->
      Redis.Client.Public.send_redis(conn, ["SAVE"])
    end
    Process.send_after(self(), :save, @save_time)
    {:noreply, [], conn}
  end

  def handle_info(_event, redis) do
    {:noreply, [], redis}
  end
end
