defmodule Farmbot.TestSupport do
  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.{FarmEvent, RegimenInstance}

  def farm_event_timeout do
    Application.get_env(:farmbot_core, FarmEvent)[:checkup_time_ms]
  end

  def regimen_instance_timeout do
    Application.get_env(:farmbot_core, RegimenInstance)[:checkup_time_ms]
  end

  def asset_monitor_timeout do
    Application.get_env(:farmbot_core, Farmbot.AssetMonitor)[:checkup_time_ms]
  end
end
