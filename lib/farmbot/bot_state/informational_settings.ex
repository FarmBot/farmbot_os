defmodule Farmbot.BotState.InformationalSettings do
  @moduledoc "Configuration data that should only be changed internally."

  defmodule SyncStatus do
    @moduledoc "Enum of all available statuses for the sync message."

    @statuses [
      :locked,
      :maintenance,
      :sync_error,
      :sync_now,
      :synced,
      :syncing,
      :unknown
    ]

    @typedoc "Status of the sync bar"
    @type t :: :locked |
               :maintenance |
               :sync_error |
               :sync_now |
               :synced |
               :syncing |
               :unknown

    def status(sts) when sts in @statuses do
      sts
    end

    def status(unknown) when is_atom(unknown) or is_binary(unknown) do
      raise "unknown sync status: #{unknown}"
    end
  end

  @version Mix.Project.config[:version]

  defstruct [
    controller_version: @version,
    firmware_version: :disconnected,
    throttled: false,
    private_ip: :disconnected,
    sync_status: SyncStatus.status(:sync_now)
  ]

  @typedoc "Information Settings."
  @type t :: %__MODULE__{
    controller_version: Version.version,
    firmware_version: :disconnected | Version.version,
    throttled: boolean,
    private_ip: :disconnected | Version.version,
    sync_status: SyncStatus.t
  }

  use Farmbot.BotState.Lib.Partition
end
