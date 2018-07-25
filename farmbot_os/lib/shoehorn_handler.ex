defmodule Farmbot.OS.ShoehornHandler do
  use Shoehorn.Handler
  require Logger

  def init do
    {:ok, %{}}
  end

  def application_exited(:farmbot_core, reason, state) do
    Logger.error "FarmbotCore exited: #{inspect reason}"
    Application.stop(:farmbot_os)
    Application.ensure_all_started(:farmbot_os)
    {:continue, state}
  end

  def application_exited(:farmbot_os, reason, state) do
    Logger.error "FarmbotOS exited: #{inspect reason}"
    Application.ensure_all_started(:farmbot_os)
    {:continue, state}
  end

  def application_exited(:farmbot_ext, reason, state) do
    Logger.error "FarmbotExt exited: #{inspect reason}"
    Application.ensure_all_started(:farmbot_ext)
    {:continue, state}
  end

  def application_exited(_app, _reason, state) do
    {:continue, state}
  end
end
