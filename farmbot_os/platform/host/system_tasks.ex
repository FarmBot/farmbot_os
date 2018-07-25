defmodule Farmbot.Host.SystemTasks do
  @moduledoc "Host implementation for Farmbot.System."

  @behaviour Farmbot.System

  def reboot() do
    shutdown()
  end

  def shutdown() do
    System.halt()
  end
end
