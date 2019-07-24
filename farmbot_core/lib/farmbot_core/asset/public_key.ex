defmodule FarmbotCore.Asset.PublicKey do
  @moduledoc """
  Public keys can be used to SSH into a device for
  debug purposes
  """

  use FarmbotCore.Asset.Schema, path: "/api/public_keys"
  alias Ecto.Changeset

  @callback ready?() :: boolean()
  @callback add_key(map()) :: :ok | term()

  schema "public_keys" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:public_key, :string)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view public_key do
    %{
      id: public_key.id,
      name: public_key.name,
      public_key: public_key.public_key
    }
  end

  def changeset(public_key, params \\ %{}) do
    public_key
    |> cast(params, [:id, :name, :public_key, :monitor, :created_at, :updated_at])
    |> validate_required([:public_key])
    |> validate_rsa()
  end

  def validate_rsa(%Changeset{valid?: true} = changeset) do
    public_key_bin = get_field(changeset, :public_key)
    case :public_key.ssh_decode(public_key_bin, :auth_keys) do
      [{_, opts}] -> 
        maybe_add_name(changeset, opts[:comment])
      [_ | _] -> 
        add_error(changeset, :public_key, "should only contain 1 key")
      _ ->
        add_error(changeset, :public_key, "could not decode public key")
    end
  end

  def validate_rsa(changeset), do: changeset

  def maybe_add_name(changeset, nil) do
    changeset
  end

  def maybe_add_name(changeset, comment) do
    if get_field(changeset, :name) do
      changeset
    else
      put_change(changeset, :name, to_string(comment))
    end
  end
end
