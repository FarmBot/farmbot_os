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
  @status [:fast_blink, :really_fast_blink, :slow_blink, :solid]

  def capture_led(color) do
    status = @status |> Enum.shuffle() |> Enum.at(0)
    do_it = fn -> apply(FarmbotCore.Leds, color, [status]) end
    cap = capture_io(do_it)
    assert cap =~ "LED STATUS:"
    assert cap =~ apply(IO.ANSI, Map.fetch!(@color_map, color), [])
  end

  test "leds" do
    capture_led(:red)
    capture_led(:blue)
    capture_led(:green)
    capture_led(:yellow)
    capture_led(:white1)
    capture_led(:white2)
    capture_led(:white3)
    capture_led(:white4)
    capture_led(:white5)
  end
end
