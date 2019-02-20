defmodule Farmbot.BotStateNG.Configuration do
  @moduledoc false
  alias Farmbot.BotStateNG.Configuration
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:arduino_debug_messages, :boolean)
    field(:auto_sync, :boolean)
    field(:beta_opt_in, :boolean)
    field(:disable_factory_reset, :boolean)
    field(:firmware_hardware, :string)
    field(:firmware_input_log, :boolean)
    field(:firmware_output_log, :boolean)
    field(:network_not_found_timer, :integer)
    field(:os_auto_update, :boolean)
    field(:sequence_body_log, :boolean)
    field(:sequence_complete_log, :boolean)
    field(:sequence_init_log, :boolean)
  end

  def new do
    %Configuration{}
    |> changeset(%{})
    |> apply_changes()
  end

  def view(configuration) do
    %{
      arduino_debug_messages: configuration.arduino_debug_messages,
      auto_sync: configuration.auto_sync,
      beta_opt_in: configuration.beta_opt_in,
      disable_factory_reset: configuration.disable_factory_reset,
      firmware_hardware: configuration.firmware_hardware,
      firmware_input_log: configuration.firmware_input_log,
      firmware_output_log: configuration.firmware_output_log,
      network_not_found_timer: configuration.network_not_found_timer,
      os_auto_update: configuration.os_auto_update,
      sequence_body_log: configuration.sequence_body_log,
      sequence_complete_log: configuration.sequence_complete_log,
      sequence_init_log: configuration.sequence_init_log
    }
  end

  def changeset(configuration, params \\ %{}) do
    configuration
    |> cast(params, [
      :arduino_debug_messages,
      :auto_sync,
      :beta_opt_in,
      :disable_factory_reset,
      :firmware_hardware,
      :firmware_input_log,
      :firmware_output_log,
      :network_not_found_timer,
      :os_auto_update,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log
    ])
  end
end
