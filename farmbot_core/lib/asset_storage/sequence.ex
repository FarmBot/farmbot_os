defmodule Farmbot.Asset.Sequence do
  @moduledoc """
  A Sequence is a list of CeleryScript nodes.
  """

  alias Farmbot.Asset.Sequence
  alias Farmbot.EctoTypes.TermType
  use Ecto.Schema
  import Ecto.Changeset
  require Farmbot.Logger

  @primary_key {:local_id, :binary_id, autogenerate: true}
  schema "sequences" do
    field(:id, :integer)
    field(:name, :string)
    field(:kind, :string)
    field(:args, TermType)
    field(:body, TermType)
  end

  @required_fields [:id, :name, :kind, :args, :body]

  def changeset(%Sequence{} = sequence, params \\ %{}) do
    sequence
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end

  @behaviour Farmbot.Asset.FarmEvent
  def schedule_event(%Sequence{} = sequence, _now) do
    Farmbot.Logger.busy 1, "[#{sequence.name}] Sequence init."
    Farmbot.Core.CeleryScript.sequence(sequence, fn(result) ->
      case result do
        :ok ->
          Farmbot.Logger.success 1, "[#{sequence.name}] Sequence complete."
        {:error, _} ->
          Farmbot.Logger.error 1, "[#{sequence.nam}] Sequece failed!"
      end
    end)
  end
end
