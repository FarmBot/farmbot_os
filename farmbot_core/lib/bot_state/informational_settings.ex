defmodule Farmbot.BotState.InformationalSettings do
  @moduledoc false
  import Farmbot.Project
  defstruct [
    target: target(),
    env: env(),
    node_name: node(),
    controller_version: version(),
    firmware_commit: arduino_commit(),
    commit: commit(),
    soc_temp: 0, # degrees celcius
    wifi_level: nil, # decibels 
    uptime: 0, # seconds
    memory_usage: 0, # megabytes
    disk_usage: 0, # percent
    firmware_version: nil,
    sync_status: :sync_now,
    last_status: :sync_now,
    locked: nil,
    cache_bust: nil,
    busy: nil
  ]
end
