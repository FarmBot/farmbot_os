defmodule Avrdude do
  @moduledoc """
  It's AVR, my dudes.
  """

  @uart_speed 115_200
  require FarmbotCore.Logger

  @spec flash(Path.t(), Path.t(), (() -> :ok)) :: {number, any()}
  def flash(hex_path, tty_path, reset_fun) do
    tty_path =
      if String.contains?(tty_path, "/dev") do
        tty_path
      else
        "/dev/#{tty_path}"
      end

    _ = File.stat!(hex_path)

    args = [
      "-patmega2560",
      "-cwiring",
      "-P#{tty_path}",
      "-b#{@uart_speed}",
      "-D",
      "-V",
      "-v",
      "-Uflash:w:#{hex_path}:i"
    ]

    FarmbotCore.Logger.info(3, "Writing firmware to MCU... #{inspect(args)}")

    call_reset_fun(reset_fun)

    result = MuonTrap.cmd("avrdude", args, stderr_to_stdout: true)

    if is_tuple(result) do
      {a, exit_code} = result
      FarmbotCore.Logger.info(3, inspect(a))
      FarmbotCore.Logger.info(3, "Exit code #{exit_code}")
    end

    result
  end

  def call_reset_fun(reset_fun) do
    try do
      reset_fun.()
    catch
      error_type, error ->
        FarmbotCore.Logger.error(1, """
        Error calling reset function: #{inspect(reset_fun)}
        error type: #{error_type}
        error: #{inspect(error)}
        """)
    end
  end

  :ok
end
