defmodule FarmbotOS.Leds.StubHandlerTest do
  use ExUnit.Case
  @status [:fast_blink, :really_fast_blink, :slow_blink, :solid]

  def capture_led(color) do
    status = @status |> Enum.shuffle() |> Enum.at(0)
    apply(FarmbotOS.Leds, color, [status])
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
