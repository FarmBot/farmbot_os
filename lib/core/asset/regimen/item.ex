defmodule FarmbotOS.Asset.Regimen.Item do
  use Ecto.Schema

  import Ecto.Changeset
  import FarmbotOS.Asset.View, only: [view: 2]

  @primary_key false
  @behaviour FarmbotOS.Asset.View

  view regimen_item do
    %{
      time_offset: regimen_item.time_offset,
      sequence_id: regimen_item.sequence_id
    }
  end

  embedded_schema do
    field(:time_offset, :integer)
    # Can't use real references here.
    field(:sequence_id, :id)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:time_offset, :sequence_id])
    |> validate_required([])
  end
end
