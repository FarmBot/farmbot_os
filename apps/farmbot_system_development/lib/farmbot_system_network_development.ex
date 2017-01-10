defmodule Module.concat([Farmbot, System, "development", Network]) do
  @moduledoc false
  @behaviour Farmbot.System.Network
  use GenServer

  def init(_) do
    spawn fn() ->
      # sleep because dev mode thinks network is up before it is technically possible.
      Process.sleep(2500)
      Farmbot.System.Network.on_connect()
    end
    {:ok, []}
  end
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def scan(_), do: []
  def start_all, do: :ok
  def stop_all, do: :ok
  def start_interface(_), do: :ok
  def stop_interface(_), do: :ok
  def restart_interface(_), do: :ok
end
