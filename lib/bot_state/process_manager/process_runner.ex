defmodule Farmbot.ProcessRunner do
  @moduledoc """
    Behavior for FarmProcess Runners (events, and farmware)
  """

  @typedoc """
    The body of this process
  """
  @type stuff :: Farmbot.BotState.ProcessTracker.Info.stuff

  @callback start_process(stuff) :: any
  @callback stop_process(stuff) :: any
end
