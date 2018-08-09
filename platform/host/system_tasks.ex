defmodule Farmbot.Host.SystemTasks do
  @moduledoc "Host implementation for Farmbot.System."

  @behaviour Farmbot.System

  def factory_reset(reason) do
    IO.inspect reason
    shutdown(reason)
  end

  def reboot(_reason) do
    Application.stop(:farmbot)
    Application.start(:farmbot)
    :init.reboot()
  end

  def shutdown(_reason) do
    :init.stop()
  end
end
