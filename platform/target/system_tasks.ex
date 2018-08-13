defmodule Farmbot.Target.SystemTasks do
  @moduledoc "Target implementation for System Tasks."

  @behaviour Farmbot.System

  def factory_reset(reason) do
    reboot(reason)
  end

  def reboot(_reason) do
    Nerves.Runtime.reboot()
  end

  def shutdown(_reason) do
    Nerves.Runtime.poweroff()
  end
end
