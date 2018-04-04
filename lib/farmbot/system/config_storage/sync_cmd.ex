defmodule Farmbot.System.ConfigStorage.SyncCmd do
  @moduledoc "describes an update to a API resource."

  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.Repo.JSONType
  alias Farmbot.System.ConfigStorage

  schema "sync_cmds" do
    field(:remote_id, :integer)
    field(:kind, :string)
    field(:body, JSONType)
    timestamps()
  end

  @required_fields [:remote_id, :kind]

  def changeset(%__MODULE__{} = cmd, params \\ %{}) do
    cmd
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  @doc """
  Register a sync message from an external source.
  This is like a snippit of the changes that have happened.
  `sync_cmd`s should only be applied on `sync`ing.
  `sync_cmd`s are _not_ a source of truth for transactions that have been applied.
  Use the `Farmbot.Asset.Registry` for these types of events.
  """
  def register_sync_cmd(_id, _kind, _body) do
    
  end
end
