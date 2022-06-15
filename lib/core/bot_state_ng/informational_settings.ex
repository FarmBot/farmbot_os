defmodule FarmbotOS.BotStateNG.InformationalSettings do
  @moduledoc false
  alias FarmbotOS.BotStateNG.InformationalSettings
  use Ecto.Schema
  import Ecto.Changeset

  alias FarmbotOS.Project

  @primary_key false

  embedded_schema do
    field(:target, :string, default: to_string(Project.target()))
    field(:env, :string, default: to_string(Project.env()))
    field(:firmware_commit, :string, default: "---")
    field(:controller_version, :string, default: Project.version())
    field(:controller_uuid, :string)
    field(:controller_commit, :string, default: Project.commit())
    field(:firmware_version, :string)
    field(:node_name, :string)
    field(:private_ip, :string)
    field(:soc_temp, :integer)
    field(:throttled, :string)
    field(:wifi_level, :integer)
    field(:wifi_level_percent, :integer)
    field(:video_devices, :string)
    field(:uptime, :integer)
    field(:memory_usage, :integer)
    field(:disk_usage, :integer)
    field(:scheduler_usage, :integer)
    field(:sync_status, :string, default: "sync_now")
    field(:locked, :boolean, default: false)
    field(:locked_at, :integer, default: 0)
    field(:last_status, :string)
    field(:cache_bust, :integer)
    field(:busy, :boolean)
    field(:idle, :boolean)
    field(:update_available, :boolean, default: false)
  end

  def new do
    %InformationalSettings{}
    |> changeset(%{})
    |> apply_changes()
  end

  def view(informational_settings) do
    %{
      target: informational_settings.target,
      env: informational_settings.env,
      controller_version: informational_settings.controller_version,
      controller_uuid: informational_settings.controller_uuid,
      controller_commit: informational_settings.controller_commit,
      # this field is required for the frontend. Maybe remove in the future.
      commit: informational_settings.controller_commit,
      firmware_commit: informational_settings.firmware_commit,
      firmware_version: informational_settings.firmware_version,
      node_name: informational_settings.node_name,
      private_ip: informational_settings.private_ip,
      soc_temp: informational_settings.soc_temp,
      throttled: informational_settings.throttled,
      wifi_level: informational_settings.wifi_level,
      wifi_level_percent: informational_settings.wifi_level_percent,
      video_devices: informational_settings.video_devices,
      uptime: informational_settings.uptime,
      memory_usage: informational_settings.memory_usage,
      disk_usage: informational_settings.disk_usage,
      scheduler_usage: informational_settings.scheduler_usage,
      cpu_usage: informational_settings.scheduler_usage,
      sync_status: informational_settings.sync_status,
      locked: informational_settings.locked,
      locked_at: informational_settings.locked_at,
      last_status: informational_settings.last_status,
      cache_bust: informational_settings.cache_bust,
      busy: informational_settings.busy,
      idle: informational_settings.idle,
      update_available: informational_settings.update_available
    }
  end

  def changeset(informational_settings, params \\ %{}) do
    informational_settings
    |> cast(params, [
      :target,
      :env,
      :controller_version,
      :controller_uuid,
      :controller_commit,
      :firmware_commit,
      :firmware_version,
      :node_name,
      :private_ip,
      :soc_temp,
      :throttled,
      :wifi_level,
      :wifi_level_percent,
      :video_devices,
      :uptime,
      :memory_usage,
      :disk_usage,
      :scheduler_usage,
      :sync_status,
      :locked,
      :locked_at,
      :last_status,
      :cache_bust,
      :busy,
      :idle,
      :update_available
    ])
  end
end
