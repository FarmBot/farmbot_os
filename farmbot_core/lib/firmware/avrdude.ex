defmodule FarmbotCore.Firmware.Avrdude do
  @uart_speed 115_200
  @max_attempts 18
  require FarmbotCore.Logger

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
    call_avr_dude(reset_fun, args)
  end

  def call_avr_dude(reset_fun, args, attempts \\ 1) do
    call_reset_fun(reset_fun)
    FarmbotCore.Logger.info(3, "Begin flash attempt #{attempts}")
    {msg, exit_code} = MuonTrap.cmd("avrdude", args, stderr_to_stdout: true)
    give_up? = attempts > @max_attempts

    if exit_code == 0 || give_up? do
      if give_up? do
        FarmbotCore.Logger.info(3, "Failed after #{attempts} attempts.")
      else
        FarmbotCore.Logger.info(3, "Firmware Flash OK")
      end

      FarmbotCore.Logger.info(3, inspect(msg))
      {msg, exit_code}
    else
      FarmbotCore.Logger.info(3, "Attempt #{attempts} failed.")
      FarmbotCore.Logger.info(3, "#{inspect(msg)}")
      call_avr_dude(reset_fun, args, attempts + 1)
    end
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
end
