defmodule FarmbotOS.Platform.Host.SystemTasks do
  @moduledoc "Host implementation for Farmbot.System."

  @behaviour FarmbotOS.System

  def reboot() do
    shutdown()
  end

  def shutdown() do
    System.halt()
  end
end
