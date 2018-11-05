defmodule Farmbot.BotStateNG.InformationalSettings do
  @moduledoc false
  alias Farmbot.BotStateNG.InformationalSettings
  use Ecto.Schema
  import Ecto.Changeset

  alias Farmbot.Project

  @primary_key false

  embedded_schema do
    field(:target, :string, default: to_string(Project.target()))
    field(:env, :string, default: to_string(Project.env()))
    field(:controller_version, :string, default: Project.version())
    field(:firmware_commit, :string, default: Project.arduino_commit())
    field(:commit, :string, default: Project.commit())
    field(:firmware_version, :string)
    field(:node_name, :string)
    field(:soc_temp, :integer)
    field(:wifi_level, :integer)
    field(:uptime, :integer)
    field(:memory_usage, :integer)
    field(:disk_usage, :integer)
    field(:sync_status, :string, default: "sync_now")
    field(:locked, :boolean, default: false)
    field(:last_status, :string)
    field(:cache_bust, :integer)
    field(:busy, :boolean)
  end

  def new do
    %InformationalSettings{}
    |> changeset(%{})
    |> apply_changes()
  end

  def changeset(informational_settings, params \\ %{}) do
    informational_settings
    |> cast(params, [
      :target,
      :env,
      :controller_version,
      :firmware_commit,
      :commit,
      :firmware_version,
      :node_name,
      :soc_temp,
      :wifi_level,
      :uptime,
      :memory_usage,
      :disk_usage,
      :sync_status,
      :locked,
      :last_status,
      :cache_bust,
      :busy
    ])
  end
end
