defmodule FarmbotCore.Asset.PersistentRegimen do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:local_id, :binary_id, autogenerate: true}
  @timestamps_opts inserted_at: :created_at, type: :utc_datetime

  schema "persistent_regimens" do
    belongs_to(:regimen, FarmbotCore.Asset.Regimen, references: :local_id, type: :binary_id)
    belongs_to(:farm_event, FarmbotCore.Asset.FarmEvent, references: :local_id, type: :binary_id)
    field(:epoch, :utc_datetime)
    field(:started_at, :utc_datetime)
    field(:next, :utc_datetime)
    # Can't use references here.
    field(:next_sequence_id, :id)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  def changeset(persistent_regimen, params \\ %{}) do
    persistent_regimen
    |> cast(params, [:started_at, :next, :next_sequence_id, :monitor])
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
    case FarmbotCore.Asset.device().timezone do
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
