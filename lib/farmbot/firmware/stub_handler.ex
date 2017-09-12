defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."
  use GenServer
  require Logger

  @doc "Start the firmware handler stub."
  def start_link(firmware, opts) do
    Logger.warn("Firmware is being stubbed.")
    GenServer.start_link(__MODULE__, firmware, opts)
  end
end
