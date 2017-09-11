defmodule Farmbot.Farmware.Installer.Repository do
  @moduledoc """
  Data Access Object for Farmware Repository
  """

  defmodule Entry do
    @moduledoc false
    @enforce_keys [:name, :manifest]
    defstruct     [:name, :manifest]

    @typedoc """
      * `name` is the name of the Farmware
      * `manifest` is the url to the manifest
    """
    @type t :: %__MODULE__{ name: binary, manifest: binary }

    @doc """
    Validates json
    """
    @spec validate!(any) :: t
    def validate!(%{"name" => name, "manifest" => manifest}) do
      %__MODULE__{name: name, manifest: manifest}
    end

    def validate!(err), do: raise "Repo entry not valid: #{inspect err}"
  end

  defstruct [:entries]

  @typedoc """
  A repository is just a list of entries.
  """
  @type t :: %__MODULE__{entries: [Entry.t]}

  @doc """
  Validates an entire repo from json
  """
  @spec validate!(any, [Entry.t]) :: t
  def validate!(json_list, acc \\ [])

  def validate!([], acc) do
    %__MODULE__{entries: acc}
  end

  def validate!([json_entry | rest], acc) do
   entry = Entry.validate!(json_entry)
   validate!(rest, [entry | acc])
  end

  @doc """
  Must return the url that holds this manifest.
  """
  @callback url :: binary
end
