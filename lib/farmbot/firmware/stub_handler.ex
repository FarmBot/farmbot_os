defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."

  use GenStage
  require Logger

  @behaviour Farmbot.Firmware.Handler

  def start_link do
    Logger.warn("Firmware is being stubbed.")
    GenStage.start_link(__MODULE__, [])
  end

  def move_absolute(pos) do
    GenStage.call(__MODULE__, {:move_absolute, pos})
  end

  defmodule State do
    defstruct []
  end

  def init([]) do
    state = %State{}
    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end
end
