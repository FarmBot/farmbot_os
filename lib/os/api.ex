defmodule FarmbotOS.API do
  @moduledoc """
  Module where all Farmbot specific HTTP calls are done
  """

  alias FarmbotOS.APIFetcher
  alias FarmbotOS.Asset.{FbosConfig, FirmwareConfig}

  @doc "helper for `GET`ing api resources."
  def get_changeset(module) when is_atom(module) do
    get_changeset(struct(module))
  end

  def get_changeset(%module{} = data) do
    APIFetcher.get_body!(module.path() <> ".json") |> unwrap(data)
  end

  @doc "helper for `GET`ing api resources."
  def get_changeset(asset, path)

  # Hacks for dealing with these resources not having #show
  def get_changeset(FbosConfig, _),
    do: get_changeset(FbosConfig)

  def get_changeset(FirmwareConfig, _),
    do: get_changeset(FirmwareConfig)

  def get_changeset(%FbosConfig{} = data, _),
    do: get_changeset(data)

  def get_changeset(%FirmwareConfig{} = data, _),
    do: get_changeset(data)

  def get_changeset(module, path) when is_atom(module) do
    get_changeset(struct(module), path)
  end

  def get_changeset(%module{} = data, path) do
    p = Path.join(module.path(), to_string(path) <> ".json")
    unwrap(APIFetcher.get_body!(p), data)
  end

  def unwrap(body, %module{} = data) do
    case body do
      {:ok, many} when is_list(many) ->
        {:ok, Enum.map(many, &module.changeset(data, &1))}

      {:ok, %{} = single} ->
        result = module.changeset(data, single)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
