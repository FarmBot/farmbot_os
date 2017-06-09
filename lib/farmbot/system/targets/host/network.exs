defmodule Module.concat([Farmbot, System, "host", Network]) do
  @moduledoc false
  @behaviour Farmbot.System.Network
  use GenServer

  def init(_) do
    {:ok, []}
  end
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def scan(_, _), do: ["testssod", "test2"]
  def enumerate(_), do: ["testiface0"]
  def start_interface(_, _, _), do: :ok
  def stop_interface(_, _), do: :ok
end
