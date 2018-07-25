defmodule Farmbot.Asset.Sequence do
  @moduledoc """
  A Sequence is a list of CeleryScript nodes.
  """

  alias Farmbot.Asset.Sequence
  alias Farmbot.EctoTypes.TermType
  use Ecto.Schema
  import Ecto.Changeset

  schema "sequences" do
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
    case Farmbot.CeleryScript.schedule_sequence(sequence) do
      %{status: :crashed} = proc -> {:error, Csvm.FarmProc.get_crash_reason(proc)}
      _ -> :ok
    end
  end
end
