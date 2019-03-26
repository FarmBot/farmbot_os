defmodule FarmbotCore.Asset.Regimen.BodyNode do
  @moduledoc """
  This is one of the node types that may or may
  not exist within the `regimen.body` array.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import FarmbotCore.Asset.View, only: [view: 2]

  @primary_key false
  @behaviour FarmbotCore.Asset.View

  embedded_schema do
    field(:kind, :string)
    # SEE CeleryScript corpus for "real" schema - RC
    field(:args, {:map, :any})
  end

  view body_node do
    %{ kind: body_node.kind, args: body_node.args }
  end

  def changeset(body_node, params \\ %{}) do
    body_node
    |> cast(params, [:kind, :args])
    |> validate_required([:kind, :args])
    |> validate_inclusion(:kind,
      ~w(parameter_application parameter_declaration variable_declaration))
  end
end
