defmodule Farmbot.System.ConfigStorage.Group do
  @moduledoc ""

  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field(:group_name, :string)
  end

  @required_fields []

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
