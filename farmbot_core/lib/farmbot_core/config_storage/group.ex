defmodule Farmbot.Config.Group do
  @moduledoc false

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
