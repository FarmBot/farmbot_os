defmodule Farmbot.System.ConfigStorage.ConfigKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "config_keys" do
    field :name, :string
  end

  @required_fields [:name]

  def changeset(config_group, params \\ %{}) do
    config_group
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
