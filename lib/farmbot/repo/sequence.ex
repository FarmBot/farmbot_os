defmodule Farmbot.Repo.Sequence do
  @moduledoc """
  A Sequence is a list of CeleryScript nodes.
  """

  alias Farmbot.Repo.JSONType
  use Ecto.Schema
  import Ecto.Changeset

  schema "sequences" do
    field(:name, :string)
    field(:kind, :string)
    field(:args, JSONType)
    field(:body, JSONType)
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name, :kind, :args, :body]

  def changeset(sequence, params \\ %{}) do
    sequence
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
