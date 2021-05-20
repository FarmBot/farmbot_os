defmodule FarmbotCore.Firmware.UARTJob do
  alias FarmbotCore.Firmware.UARTCore
  require FarmbotCore.Logger

  # A Farmbot Express takes three minutes to boot up.
  @wait_time 1000
  @max_attempts 10

  def start_job(server \\ UARTCore, gcode) do
    wait_loop(server, 1, gcode)
  end

  defp wait_loop(server, attempt_num, gcode) do
    pid = as_pid(server)
    give_up = attempt_num >= @max_attempts

    if pid || give_up do
      UARTCore.start_job_raw(server, gcode)
    else
      ms = attempt_num * @wait_time * 3
      FarmbotCore.Logger.info(3, "Waiting #{ms / 1000} seconds for firmware.")
      Process.sleep(ms)
      wait_loop(server, attempt_num + 1, gcode)
    end
  end

  defp as_pid(nil), do: nil
  defp as_pid(server) when is_pid(server), do: server

  defp as_pid(server) do
    as_pid(Process.whereis(server))
  end
end
