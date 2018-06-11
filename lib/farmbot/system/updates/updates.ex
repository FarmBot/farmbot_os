defmodule Farmbot.System.Updates do
  @moduledoc "Handles over the air updates."

  use Supervisor
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [get_config_value: 3, update_config_value: 4]

  @data_path Application.get_env(:farmbot, :data_path)
  @target Farmbot.Project.target()
  @current_version Farmbot.Project.version()
  @env Farmbot.Project.env()

  @update_handler Application.get_env(:farmbot, :behaviour)[:update_handler]
  @update_handler || Mix.raise("Please configure update_handler")


  @doc "Overwrite os update server field"
  def override_update_server(url) do
    update_config_value(:string, "settings", "os_update_server_overwrite", url)
  end

  defmodule Release do
    @moduledoc false
    defmodule Asset do
      @moduledoc false
      defstruct [:name, :browser_download_url]
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
    @moduledoc false
    import Farmbot.Project
    defstruct [
      :token,
      :beta_opt_in,
      :os_update_server_overwrite,
      :currently_on_beta,
      :env,
      :commit,
      :target,
      :version
    ]

    @doc "Get the current stuff. Fields can be replaced for testing."
    def get(replace \\ %{}) do
      os_update_server_overwrite = get_config_value(:string, "settings", "os_update_server_overwrite")
      beta_opt_in? = is_binary(os_update_server_overwrite) || get_config_value(:bool, "settings", "beta_opt_in")
      token_bin = get_config_value(:string, "authorization", "token")
      currently_on_beta? = get_config_value(:bool, "settings", "currently_on_beta")
      token = if token_bin, do: Farmbot.Jwt.decode!(token_bin), else: nil
      opts = %{
        token: token,
        beta_opt_in: beta_opt_in?,
        currently_on_beta: currently_on_beta?,
        os_update_server_overwrite: os_update_server_overwrite,
        env: env(),
        commit: commit(),
        target: target(),
        version: version()
      } |> Map.merge(Map.new(replace))
      struct(__MODULE__, opts)
    end
  end

  @doc "Downloads and applies an update file."
  def download_and_apply_update({%Version{} = version, dl_url}) do
    if @update_handler.requires_reboot?() do
      Logger.warn 1, "Can't apply update. An update is already staged. Please reboot and try again."
      {:error, :reboot_required}
    else
      fe_constant = "FBOS_OTA"
      dl_fun = Farmbot.BotState.download_progress_fun(fe_constant)
      # TODO(Connor): I'd like this to have a version number..
      dl_path = Path.join(@data_path, "ota.fw")
      results = http_adapter().download_file(dl_url, dl_path, dl_fun, "", [])
      Farmbot.BotState.clear_progress_fun(fe_constant)
      case results do
        {:ok, path} -> apply_firmware("beta" in (version.pre || []), path, true)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Force check for updates.
  Does _NOT_ download or apply update.
  """
  def check_updates(release \\ nil, current_stuff \\ nil)

  # All the HTTP Requests happen here.
  def check_updates(nil, current_stuff) do
    # Get current values.
    current_stuff_mut = %{
      token: token,
      beta_opt_in: beta_opt_in,
      os_update_server_overwrite: server_override,
      env: env,
    } = current_stuff || CurrentStuff.get()

    cond do
      # Don't allow non producion envs to check production env updates.
      env != :prod -> {:error, :wrong_env}
      # Don't check if the token is nil.
      is_nil(token) -> {:error, :no_token}
      # Allows the server to be overwrote.
      is_binary(server_override) ->
        Logger.debug 3, "Update server override: #{server_override}"
        get_release_from_url(server_override)
      # Beta updates should check twice.
      beta_opt_in ->
        Logger.debug 3, "Checking for beta updates."
        token
        |> Map.get(:beta_os_update_server)
        |> get_release_from_url()
      # Conditions exhausted. We _must_ be on a production release.
      true ->
        Logger.debug 3, "Checking for production updates."
        token
        |> Map.get(:os_update_server)
        |> get_release_from_url()
    end
    |> case do
      # Beta needs to make two requests:
      # check for a later beta update, if no later beta update,
      # Check for a later production release.
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
      # Production release; no beta. Check the release for an asset.
      %Release{} = release -> check_updates(release, current_stuff_mut)
      err -> err
    end
  end

  # Check against the release struct. Not HTTP requests from here out.
  def check_updates(%Release{} = rel, %CurrentStuff{} = current_stuff) do
    %{
      beta_opt_in: beta_opt_in,
      currently_on_beta: currently_on_beta,
      commit: current_commit,
      version: current_version,
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
        case Version.compare(current_version, %{release_version | pre: []}) do
          :lt ->
            Logger.debug 3, "Current version (#{current_version}) is less than beta release (#{release_version})"
            try_find_dl_url_in_asset(rel.assets, release_version, current_stuff)
          :eq ->
            if currently_on_beta do
              Logger.debug 3, "Current version (#{current_version}) is equal to beta release (#{release_version})"
              try_find_dl_url_in_asset(rel.assets, release_version, current_stuff)
            else
              Logger.debug 3, "Current version (#{current_version}) is equal to latest beta (#{release_version})"
              nil
            end

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

      # Conditions exhausted. No updates available.
      true ->
        comparison_str = "version check: current version: #{current_version} #{version_comp} latest release version: #{release_version} \n"<>
          "commit check: current commit: #{current_commit} latest release commit: #{release_commit}: (equal: #{commits_equal?})"

        Logger.debug 3, "No updates available: \ntarget: #{Farmbot.Project.target()}: \nprerelease: #{prerelease} \n#{comparison_str}"
        nil
    end
  end

  @doc "Finds a asset url if it exists, nil if not."
  @spec try_find_dl_url_in_asset([%Release.Asset{}], Version.t, %CurrentStuff{}) :: {Version.t, String.t}
  def try_find_dl_url_in_asset(assets, version, current_stuff)

  def try_find_dl_url_in_asset([%Release.Asset{name: name, browser_download_url: bdurl} | rest], %Version{} = release_version_obj, current_stuff) do
    release_version = to_string(release_version_obj)
    current_target = to_string(current_stuff.target)
    expected_name = "farmbot-#{current_target}-#{release_version}.fw"
    if match?(^expected_name, name) do
      {release_version_obj, bdurl}
    else
      Logger.debug 3, "Incorrect asset name for target: #{current_target}: #{name}"
      try_find_dl_url_in_asset(rest, release_version_obj, current_stuff)
    end
  end

  def try_find_dl_url_in_asset([], release_version, current_stuff) do
    Logger.warn 2, "No update in assets for #{current_stuff.target()} for #{release_version}"
    nil
  end

  @doc "HTTP request to fetch a Release."
  def get_release_from_url(url) when is_binary(url) do
    Logger.debug 3, "Checking for updates: #{url}"
    case http_adapter().get(url) do
      # This can happen on beta updates, if on an old token
      # and a new beta release was published.
      {:ok, %{status_code: 404}} ->
        Logger.warn 1, "Got a 404 checking for updates: #{url}. Fetching a new token. Try that again"
        Farmbot.Bootstrap.AuthTask.force_refresh()
        {:error, :token_refresh}

      # Decode the HTTP body as a release.
      {:ok, %{status_code: 200, body: body}} ->
        pattern = struct(Release, [assets: [struct(Release.Asset)]])
        case Poison.decode(body, as: pattern) do
          {:ok, %Release{} = rel} -> rel
          _err -> {:error, :bad_release_body}
        end

      # Error situations
      {:ok, %{status_code: _code, body: body}} -> {:error, body}
      err -> err
    end
  end

  @doc "Apply an OS (fwup) firmware."
  def apply_firmware(is_beta?, file_path, reboot) when is_boolean(is_beta?) do
    Logger.busy 1, "Applying #{@target} OS update (beta=#{is_beta?})"
    before_update()
    case @update_handler.apply_firmware(file_path) do
      :ok ->
        update_config_value(:bool, "settings", "currently_on_beta", is_beta?)
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

  # Private

  defp maybe_post_update do
    case File.read(update_file()) do
      {:ok, @current_version} -> :ok
      {:ok, old_version} ->
        Logger.info 1, "Updating from #{old_version} to #{@current_version}"
        @update_handler.post_update()
      {:error, :enoent} ->
        Logger.info 1, "Updating to #{@current_version}"
      {:error, err} -> raise err
    end
    before_update()
  end

  defp before_update, do: File.write!(update_file(), @current_version)

  defp update_file, do: Path.join(@data_path, "update")

  defp http_adapter, do: Farmbot.HTTP

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc false
  def init([]) do
    case @update_handler.setup(@env) do
      :ok ->
        maybe_post_update()
        children = [
          worker(Farmbot.System.UpdateTimer, [])
        ]
        opts = [strategy: :one_for_one]
        supervise(children, opts)
      {:error, reason} -> {:stop, reason}
    end
  end
end
