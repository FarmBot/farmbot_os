defmodule Farmbot.System.ConfigStorage.NetworkInterface do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  use Farmbot.Logger

  schema "network_interfaces" do
    field(:name, :string, null: false)
    field(:type, :string, null: false)

    ## For wireless interfaces
    field(:ssid, :string)
    field(:psk, :string)
    field(:security, :string)

    field(:ipv4_method, :string)
    field(:ipv4_address, :string)
    field(:ipv4_gateway, :string)
    field(:ipv4_subnet_mask, :string)
    field(:domain, :string)
  end

  @required_fields [:name, :type]

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
