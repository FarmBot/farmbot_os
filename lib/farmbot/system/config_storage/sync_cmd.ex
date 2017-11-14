defmodule Farmbot.System.ConfigStorage.SyncCmd do
  @moduledoc "describes an update to a API resource."

  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.Repo.JSONType

  schema "sync_cmds" do
    field(:remote_id, :integer)
    field(:kind, :string)
    field(:body, JSONType)
    timestamps()
  end

  @required_fields [:remote_id, :kind]

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
