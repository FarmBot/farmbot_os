defmodule Farmbot.Asset.FarmwareInstallation.Manifest do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  embedded_schema do
    field(:package, :string)
    field(:language, :string)
    field(:author, :string)
    field(:description, :string)
    field(:version, :string)
    field(:url, :string)
    field(:zip, :string)
    field(:executable, :string)
    field(:args, {:array, :string})
    field(:farmware_tools_version, :string, default: "latest")
    # new field
    field(:os_version_requirement, :string, default: "~> 6.5")
  end

  def view(manifest) do
    %{
      package: manifest.package,
      language: manifest.language,
      author: manifest.author,
      description: manifest.description,
      version: manifest.version,
      url: manifest.url,
      zip: manifest.zip,
      executable: manifest.executable,
      args: manifest.args,
      farmware_tools_version: manifest.farmware_tools_version,
      # new field
      os_version_requirement: manifest.os_version_requirement
    }
  end

  def changeset(fwim, params \\ %{}) do
    fwim
    |> cast(params, [
      :package,
      :language,
      :author,
      :description,
      :version,
      :url,
      :zip,
      :executable,
      :args,
      :os_version_requirement,
      :farmware_tools_version
    ])
    |> validate_required([:package, :executable, :args, :zip, :version])
    |> validate_required_os_version()
  end

  defp validate_required_os_version(changeset) do
    req = get_field(changeset, :os_version_requirement)
    cur = Farmbot.Project.version()

    match =
      try do
        Version.match?(cur, req)
      rescue
        Version.InvalidRequirementError -> :invalid_version
      end

    case match do
      true ->
        changeset

      _ ->
        add_error(changeset, :os_version_requirement, "Version requirement not met")
    end
  end
end
