defmodule Farmbot.Asset.SyncCmd do
  @moduledoc "describes an update to a API resource."

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
