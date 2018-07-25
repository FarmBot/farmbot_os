defmodule Farmbot.Config.NetworkInterface do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  require Farmbot.Logger

  schema "network_interfaces" do
    field(:name, :string, null: false)
    field(:type, :string, null: false)

    ## For wireless interfaces
    field(:ssid, :string)
    field(:psk, :string)
    field(:security, :string)

    ## EAP stuff
    field(:identity, :string)
    field(:password, :string)

    # Advanced settings.
    field(:ipv4_method, :string)
    field(:ipv4_address, :string)
    field(:ipv4_gateway, :string)
    field(:ipv4_subnet_mask, :string)
    field(:domain, :string)
    # This is a typo. It should be `nameservers`
    field(:name_servers, :string)

    field(:regulatory_domain, :string, default: "US")
  end

  @required_fields [:name, :type]

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
