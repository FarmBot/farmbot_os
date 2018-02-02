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
  end

  @required_fields [:name, :type]

  def changeset(config, params \\ %{}) do
    Logger.warn 1, "This NetworkInterface module is depricated."
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
