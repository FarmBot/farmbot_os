defmodule Farmbot.TestSupport do
  alias FarmbotCore.AssetWorker.FarmbotCore.Asset.{FarmEvent, PersistentRegimen}

  def farm_event_timeout do
    Application.get_env(:farmbot_core, FarmEvent)[:checkup_time_ms]
  end

  def persistent_regimen_timeout do
    Application.get_env(:farmbot_core, PersistentRegimen)[:checkup_time_ms]
  end

  def asset_monitor_timeout do
    Application.get_env(:farmbot_core, Farmbot.AssetMonitor)[:checkup_time_ms]
  end
end
