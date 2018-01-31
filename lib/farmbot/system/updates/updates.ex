defmodule Farmbot.System.Updates do
  @moduledoc "Handles over the air updates."
  use Supervisor

  @data_path Application.get_env(:farmbot, :data_path)
  use Farmbot.Logger

  @handler Application.get_env(:farmbot, :behaviour)[:update_handler]
  @handler || Mix.raise("Please configure update_handler")

  alias Farmbot.System.ConfigStorage

  @doc "Overwrite os update server field"
  def override_update_server(url) do
    ConfigStorage.update_config_value(:string, "settings", "os_update_server_overwrite", url)
  end

  defmodule Release do
    defmodule Asset do
      defstruct [
        :name,
        :browser_download_url
      ]
    end

    defstruct [
      tag_name: nil,
      target_commitish: nil,
      name: nil,
      draft: false,
      prerelease: true,
      body: nil,
      assets:  []
    ]
  end


  defmodule CurrentStuff do
    import Farmbot.Project
    defstruct [
      :token,
      :beta_opt_in,
      :os_update_server_overwrite,
      :env,
      :commit,
      :target,
      :version
    ]

    def get(replace \\ %{}) do
      os_update_server_overwrite = ConfigStorage.get_config_value(:string, "settings", "os_update_server_overwrite")
      beta_opt_in? = is_binary(os_update_server_overwrite) || ConfigStorage.get_config_value(:bool, "settings", "beta_opt_in")
      token_bin = ConfigStorage.get_config_value(:string, "authorization", "token")
      token = if token_bin, do: Farmbot.Jwt.decode!(token_bin), else: nil
      opts = %{
        token: token,
        beta_opt_in: beta_opt_in?,
        os_update_server_overwrite: os_update_server_overwrite,
        env: env(),
        commit: commit(),
        target: target(),
        version: version()
      } |> Map.merge(Map.new(replace))
      struct(__MODULE__, opts)
    end
  end

  @doc """
  Force check for updates.
  Does _NOT_ download or apply update.
  """
  # @spec check_updates(Release.t | nil) ::
  def check_updates(release \\ nil, current_stuff \\ nil)

  def check_updates(nil, current_stuff) do
    current_stuff_mut = %{
      token: token,
      beta_opt_in: beta_opt_in,
      os_update_server_overwrite: server_override,
      env: env,
    } = current_stuff || CurrentStuff.get()
    cond do
      env != :prod -> {:error, :wrong_env}
      is_nil(token) -> {:error, :no_token}
      is_binary(server_override) ->
        Logger.debug 3, "Update server override: #{server_override}"
        get_release_from_url(server_override)
      beta_opt_in ->
        Logger.debug 3, "Checking for beta updates."
        token
        |> Map.get(:beta_os_update_server)
        |> get_release_from_url()
      true ->
        Logger.debug 3, "Checking for production updates."
        token
        |> Map.get(:os_update_server)
        |> get_release_from_url()
    end
    |> case do
      %Release{} = release when beta_opt_in ->
        do_check_production_release = fn() ->
          token
          |> Map.get(:os_update_server)
          |> get_release_from_url()
          |> case do
            %Release{} = prod_release -> check_updates(prod_release, current_stuff_mut)
            err -> err
          end
        end
        check_updates(release, current_stuff_mut) || do_check_production_release.()
      %Release{} = release -> check_updates(release, current_stuff_mut)
      err -> err
    end
  end

  def check_updates(%Release{} = rel, %CurrentStuff{} = current_stuff) do
    %{
      beta_opt_in: beta_opt_in,
      commit: current_commit,
      version: current_version
    } = current_stuff

    release_version = String.trim(rel.tag_name, "v") |> Version.parse!()
    is_beta_release? = "beta" in (release_version.pre || [])
    version_comp = Version.compare(current_version, release_version)

    release_commit = rel.target_commitish
    commits_equal? = current_commit == release_commit

    prerelease = rel.prerelease
    cond do
      # Don't bother if the release is a draft. Not sure how/if this can happen.
      rel.draft ->
        Logger.warn 1, "Not checking draft release."
        nil

      # Only check prerelease if
      # current_version is less than or equal to release_version
      # AND
      # the commits are not equal.
      prerelease and is_beta_release? and beta_opt_in and !commits_equal? ->
        # beta release get marked as greater than non beta release, so we need
        # to manually check the versions by removing the pre part.
        case Version.compare(current_version, %{release_version | pre: nil}) do
          c when c in [:lt, :eq] ->
            Logger.debug 3, "Current version (#{current_version}) is less than or equal to beta release (#{release_version})"
            try_find_dl_url_in_asset(rel.assets, release_version, current_stuff)
          :gt ->
            Logger.debug 3, "Current version (#{current_version}) is greater than latest beta release (#{release_version})"
            nil
        end

      # if the current version is less than the release version.
      !prerelease and version_comp == :lt ->
        Logger.debug 3, "Current version is less than release."
        try_find_dl_url_in_asset(rel.assets, release_version, current_stuff)

      # If the version isn't different, but the commits are different,
      # This happens for beta releases.
      !prerelease and version_comp == :eq and !commits_equal? ->
        Logger.debug 3, "Current version is equal to release, but commits are not equal."
        try_find_dl_url_in_asset(rel.assets, release_version, current_stuff)

      true ->
        comparison_str = "version check: current version: #{current_version} #{version_comp} latest release version: #{release_version} \n"<>
          "commit check: current commit: #{current_commit} latest release commit: #{release_commit}: (equal: #{commits_equal?})"

        Logger.debug 3, "No updates available: \ntarget: #{Farmbot.Project.target()}: \nprerelease: #{prerelease} \n#{comparison_str}"
        nil
    end
  end

  def try_find_dl_url_in_asset(assets, version, current_stuff)

  def try_find_dl_url_in_asset([%Release.Asset{name: name, browser_download_url: bdurl} | rest], release_version, current_stuff) do
    release_version = to_string(release_version)
    current_target = to_string(current_stuff.target)
    expected_name = "farmbot-#{current_target}-#{release_version}.fw"
    if match?(^expected_name, name) do
      bdurl
    else
      Logger.debug 3, "Incorrect asset name for target: #{current_target}: #{name}"
      try_find_dl_url_in_asset(rest, release_version, current_stuff)
    end
  end

  def try_find_dl_url_in_asset([], release_version, current_stuff) do
    Logger.warn 2, "No update in assets for #{current_stuff.target()} for #{release_version}"
    nil
  end

  def get_release_from_url(url) when is_binary(url) do
    Logger.debug 3, "Checking for updates: #{url}"
    case http_adapter().get(url) do
      {:ok, %{status_code: 404}} ->
        Logger.warn 1, "Got a 404 checking for updates: #{url}. Fetching a new token. Try that again"
        Farmbot.Bootstrap.AuthTask.force_refresh()
        {:error, :token_refresh}
      {:ok, %{status_code: 200, body: body}} ->
        pattern = struct(Release, [assets: [struct(Release.Asset)]])
        case Poison.decode(body, as: pattern) do
          {:ok, %Release{} = rel} -> rel
          _err -> {:error, :bad_release_body}
        end
      {:ok, %{status_code: _code, body: body}} ->
        {:error, body}
      err -> err
    end
  end

  def http_adapter do
    # adapter = Application.get_env(:farmbot, :behaviour)[:http_adapter]
    # adapter || raise "No http adapter!"
    Farmbot.HTTP
  end

  @doc "Apply an OS (fwup) firmware."
  def apply_firmware(file_path, reboot) do
    Logger.busy 1, "Applying #{@target} OS update"
    before_update()
    case @handler.apply_firmware(file_path) do
      :ok ->
        Logger.success 1, "OS Firmware updated!"
        if reboot do
          Logger.warn 1, "Farmbot going down for OS update."
          Farmbot.System.reboot("OS Firmware Update.")
        end
      {:error, reason} ->
        Logger.error 1, "Failed to apply update: #{inspect reason}"
        {:error, reason}
    end
  end

  defp before_update do
    File.write!(update_file(), @current_version)
  end

  defp maybe_post_update do
    case File.read(update_file()) do
      {:ok, @current_version} -> :ok
      {:ok, old_version} ->
        Logger.info 1, "Updating from #{old_version} to #{@current_version}"
        @handler.post_update()
      {:error, :enoent} ->
        Logger.info 1, "Updating to #{@current_version}"
      {:error, err} -> raise err
    end
    before_update()
  end

  defp update_file do
    Path.join(@data_path, "update")
  end

  @doc false
  def start_link do
    :ignore
    # Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    case @handler.setup(@env) do
      :ok ->
        maybe_post_update()
        children = [
          worker(Farmbot.System.UpdateTimer, [])
        ]
        opts = [strategy: :one_for_one]
        supervise(children, opts)
      {:error, reason} ->
        {:stop, reason}
    end
  end
end
