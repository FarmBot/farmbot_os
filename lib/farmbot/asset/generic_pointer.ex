defmodule Farmbot.Asset.GenericPointer do
  @moduledoc "A GenericPointer is just a normal pointer with no special stuff."

  use Ecto.Schema
  import Ecto.Changeset

  schema "generic_pointers" do
  end

  use Farmbot.Repo.Syncable, sync: false
  @required_fields [:id]

  def changeset(peripheral, params \\ %{}) do
    peripheral
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
