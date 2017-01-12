defmodule Module.concat([Farmbot, System, "development", Network]) do
  @moduledoc false
  @behaviour Farmbot.System.Network
  use GenServer

  def init(_) do
    {:ok, []}
  end
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def scan(_), do: ["testssod", "test2"]
  def enumerate(), do: ["testiface0"]
  def start_interface(_, _), do: :ok
  def stop_interface(_), do: :ok
end
