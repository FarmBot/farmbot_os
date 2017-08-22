defmodule Farmbot.Host.FirmwareHandlerStub do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."
  use GenServer

  @doc "Start the firmware handler stub."
  def start_link(firmware, opts) do
    GenServer.start_link(__MODULE__, firmware, opts)
  end
end
