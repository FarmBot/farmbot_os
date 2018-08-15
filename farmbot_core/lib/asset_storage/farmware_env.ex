defmodule Farmbot.Asset.FarmwareEnv do
  @moduledoc """
  Environment key/value store for Farmware.
  """

  alias Farmbot.Asset.FarmwareEnv
  alias Farmbot.EctoTypes.JSONType
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:local_id, :binary_id, autogenerate: true}
  schema "farmware_envs" do
    field(:id, :integer)
    field(:key, :string)
    field(:value, JSONType)
  end

  @required_fields [:id, :key, :value]

  def changeset(%FarmwareEnv{} = fwe, params \\ %{}) do
    fwe
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
