defmodule Farmbot.Farmware.Installer do
  @moduledoc "Install Farmware from a URL."

  alias Farmbot.Farmware
  alias Farmbot.Farmware.Installer.Repository
  alias Farmbot.HTTP

  require Logger

  @current_os_version Mix.Project.config[:version]

  data_path = Application.get_env(:farmbot, :data_path) || raise "No configured data_path."
  @farmware_install_path Path.join(data_path, "farmware")

  @doc "The root dir of farmware installs."
  def install_root_path, do: @farmware_install_path

  @doc "Where on the filesystem is this Farmware installed."
  def install_path(name, %Version{} = fw_version) do
    Path.join([@farmware_install_path, name, fw_version |> to_string])
  end

  @doc "Where on the filesystem is this Farmware installed."
  def install_path(%Farmware{name: name, version: version}) do
    install_path(name, version)
  end

  @doc "Enable a repo from a url."
  def enable_repo(url_or_repo_struct, acc \\ [])

  def enable_repo(url, _acc) when is_binary(url) do
    Logger.info "Enabling repo from: #{url}"
    with {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 <- HTTP.get(url),
         {:ok, json_map} <- Poison.decode(body),
         {:ok, repo}     <- Repository.new(json_map)
    do
      case enable_repo(repo, []) do
        [] ->
          Logger.info "Successfully enabled repo."
          :ok
        list_of_entries ->
          Logger.error "Failed to enable some entries: #{inspect list_of_entries}"
          {:error, list_of_entries}
      end
    end
  end

  def enable_repo(repo = %Repository{manifests: [entry = %Repository.Entry{manifest_url: manifest_url} | entries]}, acc) do
    case install(manifest_url) do
      :ok -> enable_repo(%{repo | manifests: entries}, acc)
      {:error, _err} -> enable_repo(%{repo | manifests: entries}, [entry | acc])
    end
  end

  def enable_repo(%Repository{manifests: []}, acc), do: acc

  @doc "Install a farmware from a URL."
  def install(url) do
    Logger.info "Installing farmware from #{url}."
    with {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 <- HTTP.get(url),
         {:ok, json_map} <- Poison.decode(body),
         {:ok, farmware} <- Farmware.new(json_map),
         :ok             <- preflight_checks(farmware) do
           finish_install(farmware, json_map)
         else
           {:error, {name, version, :already_installed}} ->
             Logger.info "Farmware #{name} - #{version} is already installed."
             :ok
           {:ok, %{status_code: code, body: body}} ->
             Logger.error "Failed to fetch Farmware manifest: #{inspect code}: #{body}"
             {:error, :bad_http_response}
           {:error, {:invalid, _, _}} ->
             Logger.error "Failed to parse json"
             {:error, :bad_json}
           {:error, reason} ->
             Logger.error "Failed to install farmware from #{url}: #{inspect reason}"
             {:error, reason}

           err ->
             Logger.error "Unexpected error installing farmware. #{inspect err}"
             {:error, err}
         end
  end

  defp preflight_checks(%Farmware{} = fw) do
    Logger.info "Starting preflight checks for #{inspect fw}"
    with :ok <- check_version(fw.min_os_version_major),
         :ok <- check_directory(fw.name, fw.version)
    do
      :ok
    end
  end

  def check_version(required_os_version) when is_number(required_os_version) do
    case Version.parse!(@current_os_version).major >= required_os_version do
      true  -> :ok
      false -> {:error, "does not meet version requirement: #{required_os_version}"}
    end
  end

  # sets up directories or returns already_installed.
  defp check_directory(fw_name, %Version{} = fw_version) do
    Logger.info "Checking directories for #{fw_name} - #{fw_version}"
    install_path = install_path(fw_name, fw_version)
    manifest_path = Path.join(install_path, "manifest.json")
    if File.exists?(manifest_path) do
      {:error, {fw_name, fw_version, :already_installed}}
    else
      File.mkdir_p(install_path)
    end
  end

  # Fetches the package and unzips it.
  defp finish_install(%Farmware{} = fw, json_map) do
    Logger.info "Finishing install for #{inspect fw}"
    zip_path = "/tmp/#{fw.name}-#{fw.version}.zip"
    zip_url = fw.zip
    with {:ok, ^zip_path} <- HTTP.download_file(zip_url, zip_path),
         :ok <- unzip(fw, zip_path),
         {:ok, json} <- Poison.encode(json_map)
         do
           manifest_path = Path.join(install_path(fw), "manifest.json")
           File.write(manifest_path,json)
         end
  end

  defp unzip(%Farmware{} = fw, zip_path) do
    install_dir = install_path(fw)
    with {:ok, cur_dir} <- File.cwd,
         :ok <- File.cd(install_dir)
    do
      :zip.unzip(zip_path |> to_charlist())
      File.cd cur_dir
    end
  end
end
