defmodule Farmbot.Leds do
  @moduledoc "API for controling Farmbot LEDS."
  @led_handler Application.get_env(:farmbot, :behaviour)[:leds_handler]
  @led_handler || Mix.raise("You forgot a led handler!")

  @valid_status [:off, :solid, :slow_blink, :fast_blink]

  def red(status) when status in @valid_status do
    @led_handler.red(status)
  end

  def blue(status) when status in @valid_status do
    @led_handler.blue(status)
  end

  def green(status) when status in @valid_status do
    @led_handler.green(status)
  end

  def yellow(status) when status in @valid_status do
    @led_handler.yellow(status)
  end

  def white1(status) when status in @valid_status do
    @led_handler.white1(status)
  end

  def white2(status) when status in @valid_status do
    @led_handler.white2(status)
  end
end
