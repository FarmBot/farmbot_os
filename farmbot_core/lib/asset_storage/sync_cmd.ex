defmodule Farmbot.Asset.SyncCmd do
  @moduledoc """
  Describes an update to an API resource.

  * `remote_id` - ID of remote object change.
  * `kind` - String camel case representation of the asset kind.
  * `body` - Data for the change.
  """

  alias Farmbot.Asset.SyncCmd
  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.EctoTypes.TermType

  schema "sync_cmds" do
    field(:remote_id, :integer)
    field(:kind, :string)
    field(:body, TermType)
    timestamps()
  end

  @required_fields [:kind, :remote_id]

  def changeset(%SyncCmd{} = cmd, params \\ %{}) do
    cmd
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
