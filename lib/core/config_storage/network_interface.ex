defmodule FarmbotOS.Config.NetworkInterface do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "network_interfaces" do
    field(:name, :string)
    field(:type, :string)

    ## For wireless interfaces
    field(:ssid, :string)
    field(:psk, :string)
    field(:security, :string)

    ## EAP stuff
    field(:identity, :string)
    field(:password, :string)

    # Advanced settings.
    # this should be ipv4_address_method
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
    |> cast(
      params,
      @required_fields ++
        [
          :ssid,
          :psk,
          :security,
          :identity,
          :password,
          :ipv4_method,
          :ipv4_address,
          :ipv4_gateway,
          :ipv4_subnet_mask,
          :domain,
          :name_servers,
          :regulatory_domain
        ]
    )
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, ["wireless", "wired"])
    |> unique_constraint(:name)
  end
end
