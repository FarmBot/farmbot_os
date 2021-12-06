defmodule FarmbotOS.Asset.RegimenInstance do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:local_id, :binary_id, autogenerate: true}
  @timestamps_opts inserted_at: :created_at, type: :utc_datetime

  alias FarmbotOS.Asset.{FarmEvent, Regimen, RegimenInstance.Execution}

  schema "regimen_instances" do
    belongs_to(:regimen, Regimen,
      type: :binary_id,
      references: :local_id,
      on_replace: :delete
    )

    belongs_to(:farm_event, FarmEvent,
      type: :binary_id,
      references: :local_id,
      on_replace: :delete
    )

    has_many(:executions, Execution,
      on_delete: :delete_all,
      on_replace: :delete
    )

    field(:epoch, :utc_datetime_usec)
    field(:started_at, :utc_datetime_usec)
    field(:next, :utc_datetime_usec)
    field(:next_sequence_id, :id)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  def changeset(regimen_instance, params \\ %{}) do
    regimen_instance
    |> cast(params, [
      :started_at,
      :next,
      :next_sequence_id,
      :monitor,
      :updated_at
    ])
    |> put_epoch()
    |> cast_assoc(:regimen)
    |> cast_assoc(:farm_event)
  end

  defp put_epoch(%{valid?: true} = changeset) do
    started_at = get_field(changeset, :started_at) || DateTime.utc_now()

    if get_field(changeset, :epoch) do
      changeset
    else
      case build_epoch(started_at) do
        {:ok, epoch} -> put_change(changeset, :epoch, epoch)
        :error -> add_error(changeset, :epoch, "Missing timezone")
      end
    end
  end

  defp put_epoch(changeset), do: changeset

  # returns midnight of today
  @spec build_epoch(DateTime.t()) :: DateTime.t()
  def build_epoch(%DateTime{} = datetime) do
    case FarmbotOS.Asset.device().timezone do
      nil ->
        :error
      tz ->
        %DateTime{} = n = Timex.Timezone.convert(datetime, tz)
        opts = [hours: -n.hour, seconds: -n.second, minutes: -n.minute]
        localized_epoch = Timex.shift(n, opts)
        epoch = Timex.Timezone.convert(localized_epoch, datetime.time_zone)
        {:ok, epoch}
    end
  end
end
