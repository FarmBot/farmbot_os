defmodule Farmbot.Farmware.Installer.Repository do
  @moduledoc "A Repository is a way of enabling multiple farmware's at a time."

  defmodule Entry do
    @moduledoc "An entry in the Repository."
    defstruct [:name, :manifest_url]
  end

  defstruct [manifests: []]

  @doc "Turn a list into a Repo."
  def new(list, acc \\ struct(__MODULE__))

  def new([%{"name" => name, "manifest" => mani_url} | rest], %__MODULE__{manifests: manifests} = acc) do
    entry = struct(Entry, name: name, manifest_url: mani_url)
    new(rest, %{acc | manifests: [entry | manifests]})
  end

  def new([], acc), do: {:ok, acc}

end
