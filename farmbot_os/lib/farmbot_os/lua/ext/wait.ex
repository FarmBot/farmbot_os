defmodule FarmbotOS.Lua.Ext.Wait do
  alias FarmbotCeleryScript.SysCalls

  @three_minutes 60*1000*3
  @error "Do not use sleep for longer than three minutes."

  def wait([ms], lua) do
    wait = trunc(ms)
    if wait < @three_minutes do
      Process.sleep(wait)
      {[wait], lua}
    else
      SysCalls.send_message("error", @error, ["toast"])
      SysCalls.emergency_lock()
      {[], lua}
    end
  end
end
