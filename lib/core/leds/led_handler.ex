defmodule FarmbotOS.Leds.Handler do
  @moduledoc """
  Led behaviour.
  """

  @type status :: :off | :solid | :slow_blink | :fast_blink
  @callback red(status) :: any
  @callback blue(status) :: any
  @callback green(status) :: any
  @callback yellow(status) :: any
  @callback white1(status) :: any
  @callback white2(status) :: any
  @callback white3(status) :: any
  @callback white4(status) :: any
  @callback white5(status) :: any

  @callback start_link(any) :: GenServer.on_start()
end
