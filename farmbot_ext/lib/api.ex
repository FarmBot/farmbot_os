defmodule Farmbot.API do
  alias Farmbot.{API, JSON, JWT}
  import Farmbot.Config, only: [get_config_value: 3]
  use Tesla

  plug(Tesla.Middleware.JSON, decode: &JSON.decode/1, encode: &JSON.encode/1)
  plug(Tesla.Middleware.FollowRedirects)
  # plug(Tesla.Middleware.Logger)

  @doc false
  def client do
    binary_token = get_config_value(:string, "authorization", "token")
    {:ok, tkn} = JWT.decode(binary_token)

    uri = Map.fetch!(tkn, :iss) |> URI.parse()
    url = (uri.scheme || "https") <> "://" <> uri.host <> ":" <> to_string(uri.port)

    Tesla.build_client([
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/json"},
         {"authorization", "Bearer: " <> binary_token},
         {"user-agent", "farmbot-os"}
       ]}
    ])
  end

  @doc "helper for `GET`ing a path."
  def get_body!(path) do
    API.get!(API.client(), path)
    |> Map.fetch!(:body)
  end

  @doc "helper for `GET`ing api resources."
  def get_changeset(module) when is_atom(module) do
    get_changeset(struct(module))
  end

  def get_changeset(%module{} = data) do
    get_body!(module.path())
    |> case do
      %{} = single ->
        module.changeset(data, single)

      many when is_list(many) ->
        Enum.map(many, &module.changeset(data, &1))
    end
  end

  @doc "helper for `GET`ing api resources."
  def get_changeset(asset, path)

  # Hacks for dealing with these resources not having #show
  def get_changeset(Farmbot.Asset.FbosConfig, _),
    do: get_changeset(Farmbot.Asset.FbosConfig)

  def get_changeset(Farmbot.Asset.FirmwareConfig, _),
    do: get_changeset(Farmbot.Asset.FirmwareConfig)

  def get_changeset(%Farmbot.Asset.FbosConfig{} = data, _),
    do: get_changeset(data)

  def get_changeset(%Farmbot.Asset.FirmwareConfig{} = data, _),
    do: get_changeset(data)

  def get_changeset(module, path) when is_atom(module) do
    get_changeset(struct(module), path)
  end

  def get_changeset(%module{} = data, path) do
    get_body!(Path.join(module.path(), to_string(path)))
    |> case do
      %{} = single ->
        module.changeset(data, single)

      many when is_list(many) ->
        Enum.map(many, &module.changeset(data, &1))
    end
  end
end
