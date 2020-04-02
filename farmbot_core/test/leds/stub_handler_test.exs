defmodule FarmbotCore.Leds.StubHandlerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  @color_map %{
    :red => :red,
    :blue => :blue,
    :green => :green,
    :yellow => :yellow,
    :white1 => :white,
    :white2 => :white,
    :white3 => :white,
    :white4 => :white,
    :white5 => :white
  }

  def capture_led(color, status) do
    do_it = fn -> apply(FarmbotCore.Leds, color, [status]) end
    cap = capture_io(do_it)
    assert cap =~ "LED STATUS:"
    assert cap =~ apply(IO.ANSI, Map.fetch!(@color_map, color), [])
  end

  test "leds" do
    capture_led(:red, :solid)
    capture_led(:blue, :solid)
    capture_led(:green, :solid)
    capture_led(:yellow, :solid)
    capture_led(:white1, :solid)
    capture_led(:white2, :solid)
    capture_led(:white3, :solid)
    capture_led(:white4, :solid)
    capture_led(:white5, :solid)
  end
end
