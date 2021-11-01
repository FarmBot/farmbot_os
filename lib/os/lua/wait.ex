defmodule FarmbotOS.Lua.Wait do
  alias FarmbotOS.Celery.SysCallGlue

  @three_minutes 60 * 1000 * 3
  @error "Do not use sleep for longer than three minutes."

  def wait([ms], lua) do
    wait = trunc(ms)

    if wait < @three_minutes do
      Process.sleep(wait)
      {[wait], lua}
    else
      SysCallGlue.send_message("error", @error, ["toast"])
      SysCallGlue.emergency_lock()
      {[], lua}
    end
  end
end
