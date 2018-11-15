defmodule Farmbot.Asset.StorageAuth do
  use Ecto.Schema
  use Farmbot.Asset.Schema, path: "/api/storage_auth"

  defmodule FormData do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:key, :string)
      field(:acl, :string)
      field(:policy, :string)
      field(:signature, :string)
      field(:file, :string)
      field(:"Content-Type", :string)
      field(:GoogleAccessId, :string)
    end

    def changeset(form_data, params \\ %{}) do
      form_data
      |> cast(params, [:key, :acl, :policy, :signature, :file, :"Content-Type", :GoogleAccessId])
      |> validate_required([
        :key,
        :acl,
        :policy,
        :signature,
        :file,
        :"Content-Type",
        :GoogleAccessId
      ])
    end
  end

  @primary_key false
  embedded_schema do
    field(:verb, :string)
    field(:url, :string)
    embeds_one(:form_data, FormData)
  end

  view storage_auth do
    %{
      form_data: %{
        key: storage_auth.form_data.key,
        acl: storage_auth.form_data.acl,
        policy: storage_auth.form_data.policy,
        signature: storage_auth.form_data.signature,
        file: storage_auth.form_data.file,
        "Content-Type": storage_auth.form_data."Content-Type",
        GoogleAccessId: storage_auth.form_data."GoogleAccessId"
      },
      verb: storage_auth.verb,
      url: storage_auth.url
    }
  end

  def changeset(storage_auth, params \\ %{}) do
    storage_auth
    |> cast(params, [:verb, :url])
    |> cast_embed(:form_data)
    |> validate_required([:verb, :url, :form_data])
  end
end
