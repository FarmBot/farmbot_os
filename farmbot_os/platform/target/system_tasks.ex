defmodule FarmbotOS.Platform.Target.SystemTasks do
  @moduledoc "Target implementation for System Tasks."

  @behaviour FarmbotOS.System

  def reboot() do
    Nerves.Runtime.reboot()
  end

  def shutdown() do
    Nerves.Runtime.poweroff()
  end
end
