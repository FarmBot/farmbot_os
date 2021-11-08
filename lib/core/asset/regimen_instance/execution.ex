defmodule FarmbotOS.Asset.RegimenInstance.Execution do
  alias FarmbotOS.Asset.RegimenInstance
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:local_id, :binary_id, autogenerate: true}
  @timestamps_opts inserted_at: :created_at, type: :utc_datetime_usec

  schema "regimen_instance_executions" do
    belongs_to(:regimen_instance, RegimenInstance,
      references: :local_id,
      type: :binary_id,
      foreign_key: :regimen_instance_local_id
    )

    field :scheduled_at, :utc_datetime_usec
    field :executed_at, :utc_datetime_usec
    field :status, :string
    timestamps()
  end

  def changeset(execution, params \\ %{}) do
    execution
    |> cast(params, [:executed_at, :scheduled_at, :status])
  end
end
