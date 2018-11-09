defmodule Elixir.Farmbot.Asset.Repo.Migrations.CreateFbosConfigsTable do
  use Ecto.Migration

  def change do
    create table("fbos_configs", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:arduino_debug_messages, :boolean)
      add(:auto_sync, :boolean)
      add(:beta_opt_in, :boolean)
      add(:disable_factory_reset, :boolean)
      add(:firmware_hardware, :string)
      add(:firmware_path, :string)
      add(:firmware_input_log, :boolean)
      add(:firmware_output_log, :boolean)
      add(:firmware_debug_log, :boolean)
      add(:network_not_found_timer, :integer)
      add(:os_auto_update, :boolean)
      add(:sequence_body_log, :boolean)
      add(:sequence_complete_log, :boolean)
      add(:sequence_init_log, :boolean)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
