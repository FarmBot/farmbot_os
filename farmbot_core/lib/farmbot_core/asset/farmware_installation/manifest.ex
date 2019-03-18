defmodule FarmbotCore.Asset.FarmwareInstallation.Manifest do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false
  @acceptable_manifest_version_requirement "2.0.0"
  @acceptable_farmware_tools_version_requirement "2.0.0"

  alias FarmbotCore.Project

  defmodule Config do
    use Ecto.Schema
    @primary_key false

    embedded_schema do
      field(:label, :string)
      field(:value, :string)
      field(:order, :integer)
    end

    def view(config) do
      %{
        label: config.label,
        value: config.value,
        order: config.order
      }
    end

    def changeset(config, params) do
      config
      |> cast(params, [:label, :value, :order])
      |> validate_required([:label, :value, :order])
    end
  end

  embedded_schema do
    field(:package, :string)
    field(:language, :string)
    field(:author, :string)
    field(:description, :string)
    field(:url, :string)
    field(:zip, :string)
    field(:executable, :string)
    field(:args, :string)
    field(:config, :map, default: %{})
    field(:package_version, :string)
    field(:farmware_manifest_version, :string)
    field(:farmware_tools_version_requirement, :string, default: ">= 0.0.0")
    field(:farmbot_os_version_requirement, :string, default: "~> 8.0")
  end

  def view(manifest) do
    %{
      package: manifest.package,
      language: manifest.language,
      author: manifest.author,
      description: manifest.description,
      url: manifest.url,
      zip: manifest.zip,
      executable: manifest.executable,
      args: manifest.args,
      config: Map.new(manifest.config, fn({key, config_data}) -> {key, Config.view(config_data)} end),
      package_version: manifest.package_version,
      farmware_tools_version_requirement: manifest.farmware_tools_version_requirement,
      farmware_manifest_version: manifest.farmware_manifest_version,
      farmbot_os_version_requirement: manifest.farmbot_os_version_requirement,
    }
  end

  def changeset(fwim, params \\ %{}) do
    fwim
    |> cast(params, [
      :package,
      :language,
      :author,
      :description,
      :url,
      :zip,
      :executable,
      :args,
      :config,
      :package_version,
      :farmware_tools_version_requirement,
      :farmware_manifest_version,
      :farmbot_os_version_requirement,
    ])
    |> validate_required([
      :package,
      :author,
      :zip,
      :executable,
      :args,
      :package_version,
      :farmware_manifest_version,
      :farmbot_os_version_requirement
    ])
    |> validate_farmbot_os_version_requirement()
    |> validate_farmware_manifest_version()
    |> validate_farmware_tools_version_requirement()
    |> validate_package_version()
    |> validate_config()
    |> validate_url()
    |> validate_zip()
  end

  defp validate_farmbot_os_version_requirement(%{valid?: false} = change), do: change
  defp validate_farmbot_os_version_requirement(changeset) do
    req = get_field(changeset, :farmbot_os_version_requirement)
    cur = Project.version()

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
        add_error(changeset, :farmbot_os_version_requirement, "Version requirement not met")
    end
  end

  defp validate_farmware_manifest_version(%{valid?: false} = change), do: change
  defp validate_farmware_manifest_version(changeset) do
    req = get_field(changeset, :farmware_manifest_version)
    match =
      try do
        Version.match?(@acceptable_manifest_version_requirement, req)
      rescue
        Version.InvalidRequirementError -> :invalid_version
      end

    case match do
      true ->
        changeset

      _ ->
        add_error(changeset, :farmware_manifest_version, "Version requirement not met")
    end
  end

  # Validates the version of farmware_tools required
  defp validate_farmware_tools_version_requirement(%{valid?: false} = change), do: change
  defp validate_farmware_tools_version_requirement(changeset) do
    req = get_field(changeset, :farmware_tools_version_requirement)
    match =
      try do
        Version.match?(@acceptable_farmware_tools_version_requirement, req)
      rescue
        Version.InvalidRequirementError -> :invalid_version
      end

    case match do
      true ->
        changeset

      _ ->
        add_error(changeset, :farmware_tools_version_requirement, "Version requirement not met")
    end
  end

  defp validate_package_version(%{valid?: false} = change), do: change
  defp validate_package_version(changeset) do
    version = get_field(changeset, :package_version)
    case Version.parse(version) do
      {:ok, _} -> changeset
      :error ->
        add_error(changeset, :package_version, "not a valid semver string")
    end
  end

  defp validate_config(%{valid?: false} = change), do: change
  defp validate_config(changeset) do
    config = get_field(changeset, :config)
    Enum.reduce(config, changeset, fn
      {name, %{} = params}, changeset when is_binary(name) ->
        case Config.changeset(%Config{}, params) do
          %{valid?: true} = config_changeset ->
            validated_config_data = Ecto.Changeset.apply_changes(config_changeset)
            new_config = Map.put(config, name, validated_config_data)
            put_change(changeset, :config, new_config)
          %{valid?: false} ->
            add_error(changeset, :config, "invalid config item")
        end
      {_, _}, changeset ->
        add_error(changeset, :config, "invalid config item")
    end)
  end

  defp validate_url(%{valid?: false} = change), do: change
  defp validate_url(changeset) do
    # `url` is optional
    url = get_field(changeset, :url)
    if url do
      parse_uri(url, changeset, :url)
    else
      changeset
    end
  end

  defp validate_zip(%{valid?: false} = change), do: change
  defp validate_zip(changeset) do
    zip = get_field(changeset, :zip)
    parse_uri(zip, changeset, :zip)
  end

  defp parse_uri(url, changeset, key) do
    case URI.parse(url) do
      %{scheme: s} when s in ["file", "https", "http"] -> changeset
      _ -> add_error(changeset, key, "invalid uri")
    end
  end
end
