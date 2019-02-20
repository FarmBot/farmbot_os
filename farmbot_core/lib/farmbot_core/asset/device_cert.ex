defmodule Farmbot.Asset.DeviceCert do
  @moduledoc """
  DeviceCerts describe a connection to NervesHub
  """

  use Farmbot.Asset.Schema, path: "/api/device_cert"

  schema "device_certs" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:serial_number, :string)
    field(:tags, {:array, :string})

    timestamps()
  end

  view device_cert do
    %{
      id: device_cert.id,
      serial_number: device_cert.serial_number,
      tags: device_cert.tags
    }
  end

  def changeset(device_cert, params \\ %{}) do
    device_cert
    |> cast(params, [:id, :serial_number, :tags, :created_at, :updated_at])
    |> validate_required([])
  end
end
