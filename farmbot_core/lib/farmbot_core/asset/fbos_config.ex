defmodule FarmbotCore.Asset.FbosConfig do
  @moduledoc """
  Farmbot's configuration database
  """

  use FarmbotCore.Asset.Schema, path: "/api/fbos_config"

  schema "fbos_configs" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    # firmware
    field(:arduino_debug_messages, :boolean)
    field(:firmware_input_log, :boolean)
    field(:firmware_output_log, :boolean)
    field(:firmware_debug_log, :boolean)

    # No longer supported
    field(:firmware_hardware, :string)

    # stateful
    field(:firmware_path, :string)

    # auto_sync_channel
    field(:auto_sync, :boolean)

    # not used anymore
    field(:beta_opt_in, :boolean)

    # system
    field(:disable_factory_reset, :boolean)
    field(:network_not_found_timer, :integer)
    field(:os_auto_update, :boolean)
    field(:update_channel, :string)

    # celeryscript
    field(:sequence_body_log, :boolean)
    field(:sequence_complete_log, :boolean)
    field(:sequence_init_log, :boolean)

    # private
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view fbos_config do
    %{
      id: fbos_config.id,
      arduino_debug_messages: fbos_config.arduino_debug_messages,
      auto_sync: fbos_config.auto_sync,
      beta_opt_in: fbos_config.beta_opt_in,
      disable_factory_reset: fbos_config.disable_factory_reset,
      firmware_hardware: fbos_config.firmware_hardware,
      firmware_path: fbos_config.firmware_path,
      firmware_input_log: fbos_config.firmware_input_log,
      firmware_output_log: fbos_config.firmware_output_log,
      firmware_debug_log: fbos_config.firmware_debug_log,
      network_not_found_timer: fbos_config.network_not_found_timer,
      os_auto_update: fbos_config.os_auto_update,
      update_channel: fbos_config.update_channel,
      sequence_body_log: fbos_config.sequence_body_log,
      sequence_complete_log: fbos_config.sequence_complete_log,
      sequence_init_log: fbos_config.sequence_init_log
    }
  end

  def changeset(fbos_config, params \\ %{}) do
    fbos_config
    |> cast(params, [
      :id,
      :arduino_debug_messages,
      :auto_sync,
      :beta_opt_in,
      :disable_factory_reset,
      :firmware_hardware,
      :firmware_path,
      :firmware_input_log,
      :firmware_output_log,
      :firmware_debug_log,
      :network_not_found_timer,
      :os_auto_update,
      :update_channel,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end
end
