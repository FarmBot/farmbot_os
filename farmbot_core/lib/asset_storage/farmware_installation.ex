defmodule Farmbot.Asset.FarmwareInstallation do
  @moduledoc """
  Farmware installation url.
  """

  alias Farmbot.Asset.FarmwareInstallation
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:local_id, :binary_id, autogenerate: true}
  schema "farmware_installations" do
    field(:id, :integer)
    field(:first_party, :boolean)
    field(:url, :string)
  end

  @required_fields [:id, :url]

  def changeset(%FarmwareInstallation{} = fwi, params \\ %{}) do
    fwi
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
