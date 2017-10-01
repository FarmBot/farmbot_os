defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."
  use GenStage
  require Logger

  @doc "Start the firmware handler stub."
  def start_link(opts) do
    Logger.warn("Firmware is being stubbed.")
    GenStage.start_link(__MODULE__, [], opts)
  end

  def write(handler, string) do
    GenStage.call(handler, {:write, string})
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
