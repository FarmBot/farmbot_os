defmodule Farmbot.Target.SystemTasks do
  @moduledoc "Target implementation for System Tasks."

  @behaviour Farmbot.System

  def reboot() do
    Nerves.Runtime.reboot()
  end

  def shutdown() do
    Nerves.Runtime.poweroff()
  end
end
