defmodule Farmbot.Farmware.Installer.Repository do
  @moduledoc "A Repository is a way of enabling multiple farmware's at a time."

  alias Farmbot.Farmware.Installer.Repository.{Entry, ManifestType}
  use Ecto.Schema
  import Ecto.Changeset

  schema "farmware_repositories" do
    field :manifests, ManifestType
    field :url, :string
  end

  @required_fields [:url, :manifests]

  def changeset(%__MODULE__{} = repo, params \\ %{}) do
    repo
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:url)
  end

  @doc "Turn a list into a Repo."
  def new(list, acc \\ struct(__MODULE__))

  def new([%{"name" => name, "manifest" => mani_url} | rest], %__MODULE__{manifests: manifests} = acc) do
    entry = struct(Entry, name: name, manifest: mani_url)
    new(rest, %{acc | manifests: [entry | manifests || []]})
  end

  def new([], acc), do: {:ok, acc}
end
