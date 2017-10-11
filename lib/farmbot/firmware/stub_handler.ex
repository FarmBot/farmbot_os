defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."
  use GenStage
  require Logger

  @behaviour Farmbot.Firmware.Handler

  def start_link do
    Logger.warn("Firmware is being stubbed.")
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def write(code) do
    GenStage.call(__MODULE__, {:write, code})
  end

  def init([]) do
    {:producer, []}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end

  def handle_call({:write, _string}, _from, state) do
    {:reply, :ok, state}
  end
end
