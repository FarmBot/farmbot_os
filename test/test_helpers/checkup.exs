defmodule Farmbot.Test.Helpers.Checkup do

  defp do_exit do
    Mix.shell.info([:red, "Farmbot isn't alive. Not testing."])
    System.halt(255)
  end

  def checkup do
    fb_pid = Process.whereis(Farmbot.Supervisor) || do_exit()
    Process.alive?(fb_pid)                       || do_exit()
    Process.sleep(500)
    checkup()
  end
end
