defmodule Farmbot.Farmware.Installer.Repository.SyncTask do
  @moduledoc """
  Init module for installing first party farmware repo. Requires internet.
  """

  use Task, restart: :transient
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [get_config_value: 3]
  alias Farmbot.Farmware
  alias Farmware.Installer

  @data_path Application.get_env(:farmbot, :data_path) || raise "No configured data_path."

  @doc false
  def start_link(_) do
    sync_all()
    maybe_install_farmware_tools()
    :ignore
  end

  def maybe_install_farmware_tools do
    try do
      release_url = get_config_value(:string, "settings", "farmware_tools_release_url")
      install_commit = get_config_value(:string, "settings", "farmware_tools_install_commit")
      commit_and_url_or_nil = get_install_url(release_url, install_commit)
      if commit_and_url_or_nil do
          Logger.busy 3, "Downloading Farmware tools."
          do_install_farmware_tools(commit_and_url_or_nil)
          Logger.success 3, "Downloaded Farmware tools."
      else
        Logger.debug 3, "Farmware tools up to date."
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

  def do_install_farmware_tools({commit, zipball_url}) when is_binary(commit) and is_binary(zipball_url) do
    farmware_tools_root_path = Path.join(@data_path, "farmware_tools")
    zip_file = "/tmp/farmware-tools.zip"

    File.mkdir_p!(farmware_tools_root_path)
    {:ok, ^zip_file} = Farmbot.HTTP.download_file(zipball_url, zip_file)

    fun = fn({:zip_file, dir, _info, _, _, _}) ->
      [_ | rest] = Path.split(to_string(dir))
      List.first(rest) == "farmware_tools"
    end

    case :zip.extract(~c(#{zip_file}), [:memory, file_filter: fun]) do
      {:ok, list} when is_list(list) ->
        Enum.each(list, fn({filename, data}) ->
          out_file = Path.join([farmware_tools_root_path, Path.basename(to_string(filename))])
          File.write!(out_file, data)
        end)
      {:error, reason} -> raise(reason)
    end
  end

  def sync_all do
    Logger.busy 2, "Syncing all Farmware repos. This may take a while."
    setup_repos()

    synced = fetch_and_sync()
    fw_dir = Installer.install_root_path
    if File.exists?(fw_dir) do
      sync_not_in_repos(fw_dir, synced)
    end
  end

  defp setup_repos do
    # first party farmware url could be nil. This would mean it is disabled.
    fpf_url = get_config_value(:string, "settings", "first_party_farmware_url")
    # if fpf_url isn't nil, check if its been enabled, if not enable it.
    if fpf_url do
      unless ConfigStorage.get_farmware_repo_by_url(fpf_url) do
        Installer.add_repo(fpf_url)
      end
    else
      Logger.warn 2, "First party farmware is disabled."
    end
  end

  defp fetch_and_sync do
    repos = ConfigStorage.all_farmware_repos()
    Enum.reduce(repos, [], fn(repo, acc) ->
      case Installer.sync_repo(repo) do
        {:ok, list_of_entries} ->
          Enum.map(list_of_entries, &(Map.get(&1, :name))) ++ acc
        {:error, _} -> acc
      end
    end)
  end

  defp sync_not_in_repos(fw_dir, synced) do
    all_fws = File.ls!(fw_dir)
    not_in_repos = all_fws -- synced
    for fw_name <- not_in_repos do
      case Farmware.lookup(fw_name) do
        {:ok, %Farmware{} = farmware} ->
          Logger.busy 3, "Syncing: #{inspect farmware}"
          Installer.install(farmware.url)
        _ -> :ok
      end
    end
  end

end
