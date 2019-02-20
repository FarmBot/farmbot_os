defmodule Elixir.Farmbot.Asset.DiagnosticDump do
  @moduledoc """
  """

  use Farmbot.Asset.Schema, path: "/api/diagnostic_dumps"

  schema "diagnostic_dumps" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:ticket_identifier, :string)
    field(:fbos_commit, :string)
    field(:fbos_version, :string)
    field(:firmware_commit, :string)
    field(:firmware_state, :string)
    field(:network_interface, :string)
    field(:fbos_dmesg_dump, :string)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view diagnostic_dump do
    %{
      id: diagnostic_dump.id,
      ticket_identifier: diagnostic_dump.ticket_identifier,
      fbos_commit: diagnostic_dump.fbos_commit,
      fbos_version: diagnostic_dump.fbos_version,
      firmware_commit: diagnostic_dump.firmware_commit,
      firmware_state: diagnostic_dump.firmware_state,
      network_interface: diagnostic_dump.network_interface,
      fbos_dmesg_dump: diagnostic_dump.fbos_dmesg_dump
    }
  end

  def changeset(diagnostic_dump, params \\ %{}) do
    diagnostic_dump
    |> cast(params, [
      :id,
      :ticket_identifier,
      :fbos_commit,
      :fbos_version,
      :firmware_commit,
      :firmware_state,
      :network_interface,
      :fbos_dmesg_dump,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end
end
