defmodule Farmbot.Asset.Tool do
  @moduledoc "A Tool is an item that lives in a ToolSlot"

  alias Farmbot.Asset.Tool
  use Ecto.Schema
  import Ecto.Changeset

  schema "tools" do
    field(:name, :string)
  end

  @required_fields [:id, :name]

  def changeset(%Tool{} = tool, params \\ %{}) do
    tool
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
