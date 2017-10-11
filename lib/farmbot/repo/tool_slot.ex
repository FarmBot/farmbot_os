defmodule Farmbot.Repo.ToolSlot do
  @moduledoc "A ToolSlot is the Point to a Tool."

  use Ecto.Schema
  import Ecto.Changeset

  schema "tool_slots" do
    field(:tool_id, :integer)
  end

  use Farmbot.Repo.Syncable, sync: false
  @required_fields [:id, :tool_id]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
