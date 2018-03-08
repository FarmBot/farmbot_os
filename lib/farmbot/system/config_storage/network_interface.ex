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
    field(:migrated, :boolean)
    field(:maybe_hidden, :boolean)
  end

  @required_fields [:name, :type]

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
