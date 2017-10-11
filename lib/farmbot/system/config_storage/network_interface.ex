defmodule Farmbot.System.ConfigStorage.NetworkInterface do
  @moduledoc ""

  use Ecto.Schema
  import Ecto.Changeset

  schema "network_interfaces" do
    field(:name, :string, null: false)
    field(:type, :string, null: false)

    ## For wireless interfaces
    field(:ssid, :string)
    field(:psk, :string)
    field(:security, :string)

    field(:ipv4_method, :string)
  end

  @required_fields [:name, :type]

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
