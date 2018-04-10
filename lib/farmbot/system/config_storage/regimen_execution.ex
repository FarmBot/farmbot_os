defmodule Farmbot.System.ConfigStorage.RegimenExecution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "regimen_executions" do
    field :regimen_id, :integer
    field :executable_id, :integer
    field :epoch, :utc_datetime
    field :hash, :string
  end

  @required_fields [:regimen_id, :executable_id, :epoch, :hash]

  def changeset(re, params \\ %{}) do
    re
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
