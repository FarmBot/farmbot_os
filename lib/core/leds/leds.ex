defmodule FarmbotOS.Leds do
  @moduledoc "API for controlling Farmbot LEDS."

  @valid_status [:off, :solid, :slow_blink, :fast_blink, :really_fast_blink]

  def red(status) when status in @valid_status, do: led_handler().red(status)
  def blue(status) when status in @valid_status, do: led_handler().blue(status)

  def green(status) when status in @valid_status,
    do: led_handler().green(status)

  def yellow(status) when status in @valid_status,
    do: led_handler().yellow(status)

  def white1(status) when status in @valid_status,
    do: led_handler().white1(status)

  def white2(status) when status in @valid_status,
    do: led_handler().white2(status)

  def white3(status) when status in @valid_status,
    do: led_handler().white3(status)

  def white4(status) when status in @valid_status,
    do: led_handler().white4(status)

  def white5(status) when status in @valid_status,
    do: led_handler().white5(status)

  def led_handler,
    do: Application.get_env(:farmbot, __MODULE__)[:gpio_handler]

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {led_handler(), :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
