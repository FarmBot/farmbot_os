defmodule Farmbot.Leds.StubHandler do
  @moduledoc false
  use Farmbot.Logger

  @behaviour Farmbot.Leds.Handler

  def red(status) do
    do_debug(:red, status)
  end

  def blue(status) do
    do_debug(:blue, status)
  end

  def green(status) do
    do_debug(:green, status)
  end

  def yellow(status) do
    do_debug(:yellow, status)
  end

  def white1(status) do
    do_debug(:white, status)
  end

  def white2(status) do
    do_debug(:white, status)
  end

  defp do_debug(color, status) do
    msg = ["LED STATUS: ",
           apply(IO.ANSI, color, []),
           status_in(status),
           to_string(color),
           " ",
           to_string(status),
           status_out(status),
           IO.ANSI.normal()
         ]
    IO.puts(msg)
  end

  defp status_in(:slow_blink), do: IO.ANSI.blink_slow()
  defp status_in(:fast_blink), do: IO.ANSI.blink_rapid()
  defp status_in(_), do: ""

  defp status_out(:slow_blink), do: IO.ANSI.blink_off()
  defp status_out(:fast_blink), do: IO.ANSI.blink_off()
  defp status_out(_), do: ""
end
