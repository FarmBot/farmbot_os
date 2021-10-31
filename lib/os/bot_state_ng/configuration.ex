defmodule FarmbotOS.BotStateNG.Configuration do
  @moduledoc false
  alias FarmbotOS.BotStateNG.Configuration
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:firmware_hardware, :string)
    field(:firmware_input_log, :boolean)
    field(:firmware_output_log, :boolean)
    field(:firmware_debug_log, :boolean)
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
      firmware_hardware: configuration.firmware_hardware,
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
      :firmware_hardware,
      :network_not_found_timer,
      :os_auto_update,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log
    ])
  end
end
