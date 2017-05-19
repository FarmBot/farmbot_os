defmodule Farmbot.ProcessRunner do
  @moduledoc """
    Behavior for FarmProcess Runners (events, and farmware)
  """

  alias Farmbot.Context

  @typedoc """
    The body of this process
  """
  @type stuff :: Farmbot.BotState.ProcessTracker.Info.stuff

  @callback start_process(Context.t, stuff) :: any
  @callback stop_process(Context.t, stuff) :: any
end
