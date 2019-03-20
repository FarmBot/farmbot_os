defmodule Avrdude do
  @moduledoc """
  It's AVR, my dudes.
  """

  @uart_speed 115_200

  def flash(hex_path, tty_path) do
    # STEP 1: Is the UART in use?
    args = [
      "-patmega2560",
      "-cwiring",
      "-P#{tty_path}",
      "-b#{@uart_speed}",
      "-D",
      "-V",
      "-Uflash:w:#{hex_path}:i"
    ]

    MuonTrap.cmd("avrdude", args, into: IO.stream(:stdio, :line))
  end
end
