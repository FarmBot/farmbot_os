defmodule Farmbot.Asset.Tool do
  @moduledoc "A Tool is an item that lives in a ToolSlot"

  use Ecto.Schema
  import Ecto.Changeset

  schema "tools" do
    field(:name, :string)
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
