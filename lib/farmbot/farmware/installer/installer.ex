defmodule Farmbot.Farmware.Installer do
  @moduledoc "Handles installation of Farmwares and syncronization of Farmware Repos."

  alias Farmbot.Farmware
  alias Farmbot.Farmware.Installer.Repository
  alias Farmbot.HTTP
  alias Farmbot.System.ConfigStorage

  use Farmbot.Logger

  @current_os_version Farmbot.Project.version()

  data_path = Application.get_env(:farmbot, :data_path) || raise "No configured data_path."
  @farmware_install_path Path.join(data_path, "farmware")

  def install_farmware_tools(%Farmware{} = fw) do
    release_url = "https://api.github.com/repos/FarmBot-Labs/farmware-tools/releases/#{fw.farmware_tools_version}"
    installed_commit = nil
    path = install_path(fw)
    maybe_install_farmware_tools(release_url, installed_commit, path)
    :ok
  end

  def maybe_install_farmware_tools(release_url, installed_commit, farmware_tools_root_path) do
    try do
      commit_and_url_or_nil = get_install_url(release_url, installed_commit)
      if commit_and_url_or_nil do
          Logger.busy 3, "Downloading Farmware tools: #{release_url}"
          do_install_farmware_tools(commit_and_url_or_nil, farmware_tools_root_path)
          Logger.success 3, "Downloaded Farmware tools: #{release_url}"
      else
        Logger.debug 3, "Farmware tools up to date: #{release_url}"
      end

    rescue
      reason -> Logger.error 1, "Failed to install Farmware Tools: #{Exception.message(reason)}"
    end
  end

  def get_install_url(release_url, installed_commit) do
    case :httpc.request(:get, {~c(#{release_url}), [{~c(user-agent), ~c(farmbot-os)}, {~c(content-type), ~c(application/json)}]}, [], [{:body_format, :binary}]) do
      {:ok, {{_, 200, _}, _, msg}} ->
        release = Poison.decode!(msg)
        release_commit = release["target_commitish"]
        if release_commit != installed_commit do
          {release_commit, release["zipball_url"]}
        else
          nil
        end
      {:ok, {{_, _, _}, _, msg}} ->
        message = Poison.decode!(msg) |> Map.get("message") || msg
        Logger.error 1, "Could not check for farmware_tools updates #{release_url}: [#{to_string(message)}]"
        nil
    end
  end

  def do_install_farmware_tools({commit, zipball_url}, farmware_tools_root_path) when is_binary(commit) and is_binary(zipball_url) do
    zip_file = "/tmp/farmware-tools.zip"
    File.rm_rf(zip_file)

    File.mkdir_p!(Path.join([farmware_tools_root_path, "farmware_tools"]))
    {:ok, ^zip_file} = Farmbot.HTTP.download_file(zipball_url, zip_file)

    fun = fn({:zip_file, dir, _info, _, _, _}) ->
      [_ | rest] = Path.split(to_string(dir))
      List.first(rest) == "farmware_tools"
    end

    case :zip.extract(~c(#{zip_file}), [:memory, file_filter: fun]) do
      {:ok, list} when is_list(list) ->
        Enum.each(list, fn({filename, data}) ->
          out_file = Path.join([farmware_tools_root_path, "farmware_tools", Path.basename(to_string(filename))])
          File.write!(out_file, data)
        end)
      {:error, reason} -> raise(reason)
    end

    :ok
  end

  @doc "The root dir of farmware installs."
  def install_root_path, do: @farmware_install_path

  @doc "Where on the filesystem is this Farmware installed."
  def install_path(%Farmware{name: name}) do
    install_path(name)
  end

  def install_path(name) when is_binary(name) do
    Path.join([@farmware_install_path, name])
  end

  @doc "Add a repository to the database."
  def add_repo(url) do
    with {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 <- HTTP.get(url),
         {:ok, json_map} <- Poison.decode(body),
         {:ok, manifest} <- Repository.new(json_map)
    do
      ConfigStorage.add_farmware_repo(manifest, url)
    end
    rescue
      e in Sqlite.DbConnection.Error ->
        st = System.stacktrace
        if String.contains?(Exception.message(e), "UNIQUE constraint") do
          {:error, :repo_already_exists}
        else
          reraise e, st
        end
  end

  @doc "Enable a repo from a url or struct."
  def sync_repo(url_or_repo_struct, success \\ [], fail \\ [])

  def sync_repo(url, [], []) when is_binary(url) do
    Logger.busy 2, "Syncing repo from: #{url}"
    with {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 <- HTTP.get(url),
         {:ok, json_map} <- Poison.decode(body),
         {:ok, repo}     <- Repository.new(json_map)
    do
      sync_repo(repo, [], [])
    end
  end

  def sync_repo(%Repository{manifests: [%Repository.Entry{manifest: manifest_url} = entry | entries]} = repo, success, fails) do
    case install(manifest_url) do
      :ok -> sync_repo(%{repo | manifests: entries}, [entry | success], fails)
      {:error, _err} -> sync_repo(%{repo | manifests: entries}, success, [entry | fails])
    end
  end

  def sync_repo(%Repository{manifests: []}, success, []), do: {:ok, success}
  def sync_repo(%Repository{manifests: []}, _success, failed), do: {:error, failed}

  @doc "Install a farmware from a URL."
  def install(url) do
    Logger.busy 2, "Installing farmware from #{url}."
    with {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 <- HTTP.get(url),
         {:ok, json_map} <- Poison.decode(body),
         {:ok, farmware} <- Farmware.new(json_map),
         :ok             <- preflight_checks(farmware)
         do
           finish_install(farmware, Map.put(json_map, "url", url))
         else
           {:error, {name, version, :already_installed}} ->
             {:ok, fw} = Farmbot.Farmware.lookup(name)
             Farmbot.BotState.register_farmware(fw)
             Logger.info 2, "Farmware #{name} - #{version} is already installed."
             :ok
           {:ok, %{status_code: code, body: body}} ->
             Logger.error 2, "Failed to fetch Farmware manifest: #{inspect code}: #{body}"
             {:error, :bad_http_response}
           {:error, {:invalid, _, _}} ->
             Logger.error 2, "Failed to parse json"
             {:error, :bad_json}
           {:error, reason} ->
             Logger.error 2, "Failed to install farmware from #{url}: #{inspect reason}"
             {:error, reason}
           err ->
             Logger.error 2, "Unexpected error installing farmware. #{inspect err}"
             {:error, err}
         end
  end

  def uninstall(%Farmware{} = fw) do
    Logger.warn 2, "Uninstalling farmware: #{inspect fw}"
    install_path = install_path(fw)
    case File.rm_rf(install_path) do
      {:ok, _} ->
        Farmbot.BotState.unregister_farmware(fw)
      {:error, _} = err -> err
    end
  end

  defp preflight_checks(%Farmware{} = fw) do
    Logger.info 2, "Starting preflight checks for #{inspect fw}"
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
    Logger.info 2, "Checking directories for #{fw_name} - #{fw_version}"
    install_path = install_path(fw_name)
    manifest_path = Path.join(install_path, "manifest.json")
    if File.exists?(manifest_path) do
      case File.read!(manifest_path) |> Poison.decode!() |> Map.get("version") |> Version.parse!() |> Version.compare(fw_version) do
        :eq ->
          {:error, {fw_name, fw_version, :already_installed}}
        _ ->
          File.rm_rf(install_path)
          File.mkdir_p(install_path)
      end
    else
      File.mkdir_p(install_path)
    end
  end

  # Fetches the package and unzips it.
  defp finish_install(%Farmware{} = fw, json_map) do
    Logger.success 2, "Finishing install for #{inspect fw}"
    zip_path = "/tmp/#{fw.name}-#{fw.version}.zip"
    zip_url = fw.zip
    with {:ok, ^zip_path} <- HTTP.download_file(zip_url, zip_path),
         :ok <- unzip(fw, zip_path),
         :ok <- install_farmware_tools(fw),
         {:ok, json} <- Poison.encode(json_map),
         manifest_path <- Path.join(install_path(fw), "manifest.json"),
         :ok <- File.write(manifest_path, json)
    do
      Farmbot.BotState.register_farmware(fw)
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
