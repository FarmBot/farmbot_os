defmodule Farmbot.TestSupport do

  def farm_event_timeout do
    Application.get_env(:farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent)[:checkup_time_ms] + asset_monitor_timeout() + grace()
  end

  def asset_monitor_timeout do
    Application.get_env(:farmbot_core, Farmbot.AssetMonitor)[:checkup_time_ms]
  end

  def grace do
    5000
  end
end
