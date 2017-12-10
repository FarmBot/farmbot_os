defmodule Farmbot.System.Debug.SSDPServer do
  @moduledoc false

  use GenServer
  alias Nerves.SSDPServer

  @ssdp_fields [
    server: "Farmbot",
    "cache-control": "max-age=1800",
  ]

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    timer = Process.send_after(self(), :publish, 100)
    uuid = UUID.uuid1
    {:ok, %{uuid: uuid, timer: timer}, :hibernate}
  end

  def handle_info(:publish, %{uuid: uuid} = state) do
    SSDPServer.publish "farmbot:#{uuid}", "nerves:farmbot:#{node()}", @ssdp_fields
    timer = Process.send_after(self(), :publish, 15_000)
    {:noreply, %{state | timer: timer}, :hibernate}
  end
end
