defmodule Module.concat([Farmbot, System, "rpi3", Network]) do
  @moduledoc false
  @behaviour Farmbot.System.Network
  use GenServer
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def init(_), do: {:ok, []}
  def scan(_), do: []
  def start_all, do: :ok
  def stop_all, do: :ok
  def start_interface(_), do: :ok
  def stop_interface(_), do: :ok
  def restart_interface(_), do: :ok
end
