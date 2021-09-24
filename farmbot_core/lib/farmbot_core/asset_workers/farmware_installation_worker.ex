defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.FarmwareInstallation do
  use GenServer
  require Logger

  alias FarmbotCore.{Asset.Repo, BotState, JSON}
  alias FarmbotCore.Asset.FarmwareInstallation, as: FWI
  alias FarmbotCore.Asset.FarmwareInstallation.Manifest

  @install_dir "/tmp/farmware"
  @error_retry_time_ms 25_000
  @back_off_time_ms  5_000
  @manifest_name "manifest.json"

  def preload(%FWI{}), do: []

  def tracks_changes?(%FWI{}), do: false

  def start_link(fwi, _args) do
    GenServer.start_link(__MODULE__, fwi)
  end

  def init(fwi) do
    {:ok, %{fwi: fwi, backoff: 0}, 0}
  end

  def handle_cast(:update, state) do
    {:noreply, state, 0}
  end

  def handle_info(:timeout, %{fwi: %{manifest: nil} = fwi} = state) do
    with {:ok, %{} = manifest} <- get_manifest_json(fwi),
         %{valid?: true} = changeset <- FWI.changeset(fwi, %{manifest: manifest}),
         {:ok, %FWI{} = updated} <- Repo.update(changeset),
         {:ok, zip_binary} <- get_zip(updated),
         :ok <- install_zip(updated, zip_binary),
         :ok <- install_farmware_tools(updated),
         :ok <- write_manifest(updated) do
      # TODO(Connor) -> No reason to keep this process alive?
      BotState.report_farmware_installed(updated.manifest.package, Manifest.view(updated.manifest))
      {:noreply, %{state | backoff: 0}}
    else
      error ->
        backoff = state.backoff + @back_off_time_ms
        timeout = @error_retry_time_ms + backoff
        error_log(fwi, "Failed to download Farmware manifest. Trying again in #{timeout}ms #{inspect(error)}")
        {:noreply, %{state | backoff: backoff}, timeout}
    end
  end

  # Updating a Farmware is a contentious issue.
  # Examples:
  #   * update farmbot os, a previously installed farmware may be incompatible
  #   * update farmbot os, a previously installed farmware may be using backwards
  #     incompatible APIS in farmware tools (because farmware tools wasn't updated)
  def handle_info(:timeout, %{fwi: %FWI{} = fwi} = state) do
    with {:ok, %{} = i_manifest} <- load_manifest_json(fwi),
         %{valid?: true} = d_changeset <- FWI.changeset(fwi, %{manifest: i_manifest}),
         %FWI{} = dirty <- Ecto.Changeset.apply_changes(d_changeset),
         {:ok, n_manifest} <- get_manifest_json(fwi),
         %{valid?: true} = n_changeset <- FWI.changeset(fwi, %{manifest: n_manifest}),
         {:ok, %FWI{} = updated} <- Repo.update(n_changeset) do
      maybe_update(%{state | fwi: dirty}, updated)
    else
      # Farmware wasn't found. Reinstall
      {:error, :enoent} ->
        error_log(fwi, "farmware not installed. Maybe uninstalled out of band?")
        updated =
          FWI.changeset(fwi, %{manifest: nil, updated_at: fwi.updated_at})
          |> Repo.update!()

        {:noreply, %{state | fwi: updated}, 0}

      error ->
        backoff = state.backoff + @back_off_time_ms
        timeout = @error_retry_time_ms + backoff
        error_log(fwi, "failed to check for updates. Trying again in #{timeout}ms #{inspect(error)}")
        {:noreply, %{state | backoff: backoff}, timeout}
    end
  end

  def maybe_update(%{fwi: %FWI{} = installed_fwi} = state, %FWI{} = updated) do
    case Version.compare(installed_fwi.manifest.package_version, updated.manifest.package_version) do
      # Installed is newer than remote.
      :gt ->
        success_log(updated, "up to date.")
        BotState.report_farmware_installed(updated.manifest.package, Manifest.view(updated.manifest))

        {:noreply, %{state | fwi: updated}}

      # No difference between installed and remote.
      :eq ->
        success_log(updated, "up to date.")
        BotState.report_farmware_installed(updated.manifest.package, Manifest.view(updated.manifest))

        {:noreply, %{state | fwi: updated}}

      # Installed version is older than remote
      :lt ->
        success_log(updated, "update available.")

        with {:ok, zip_binary} <- get_zip(updated),
             :ok <- install_zip(updated, zip_binary),
             :ok <- install_farmware_tools(updated),
             :ok <- write_manifest(updated) do
          BotState.report_farmware_installed(updated.manifest.package, Manifest.view(updated.manifest))
          {:noreply, %{state | fwi: updated, backoff: 0}}

        else
          er ->
            backoff = state.backoff + @back_off_time_ms
            timeout = @error_retry_time_ms + backoff
            error_log(updated, "update failed. Trying again in #{timeout}ms #{inspect(er)}")
            {:noreply, %{state | fwi: updated, backoff: backoff}, timeout}
        end
    end
  end

  def get_manifest_json(%FWI{url: "file://" <> path}) do
    case File.read(Path.join(Path.expand(path), @manifest_name)) do
      {:ok, data} -> JSON.decode(data)
      err -> err
    end
  end

  def get_manifest_json(%FWI{url: url}) do
    with {:ok, {{_, 200, _}, _headers, data}} <- get(url) do
      JSON.decode(data)
    end
  end

  def load_manifest_json(%FWI{manifest: %{}} = fwi) do
    with {:ok, data} <- File.read(Path.join(install_dir(fwi), @manifest_name)) do
      JSON.decode(data)
    end
  end

  def get_zip(%FWI{manifest: %{zip: url}}), do: get_zip(url)

  def get_zip("file://" <> path) do
    Logger.debug(1, "Using local directory for Farmware zip")

    with {:ok, files} <- File.ls(path),
         file_list <-
           Enum.map(files, fn filename ->
             {to_charlist(filename), File.read!(Path.join(path, filename))}
           end),
         {:ok, {_path, zip_binary}} <- :zip.create(to_charlist(path), file_list, [:memory]) do
      {:ok, zip_binary}
    end
  end

  def get_zip(url) when is_binary(url) do
    with {:ok, {{_, 200, _}, _headers, zip_binary}} <- get(url),
         {:ok, zip} <- :zip.zip_open(zip_binary, [:memory]),
         :ok <- :zip.zip_close(zip) do
      {:ok, zip_binary}
    end
  end

  def install_zip(%FWI{} = fwi, binary) when is_binary(binary) do
    install_zip(install_dir(fwi), binary)
  end

  def install_zip(dir, binary) do
    with {:ok, _} <- :zip.extract(binary, [{:cwd, dir}]) do
      :ok
    end
  end

  defp write_manifest(%FWI{manifest: manifest} = fwi) do
    json = Manifest.view(manifest) |> JSON.encode!()

    fwi
    |> install_dir()
    |> Path.join(@manifest_name)
    |> File.write(json)
  end

  def install_farmware_tools(%FWI{manifest: %{farmware_tools_version_requirement: _version}} = fwi) do
    install_dir = install_dir(fwi)
    File.mkdir_p(Path.join(install_dir, "farmware_tools"))

    release_url = "https://api.github.com/repos/FarmBot-Labs/farmware-tools/releases/latest"
      # if version == "latest" do
      #   "https://api.github.com/repos/FarmBot-Labs/farmware-tools/releases/latest"
      # else
      #   "https://api.github.com/repos/FarmBot-Labs/farmware-tools/releases/tags/#{version}"
      # end

    with {:ok, {_commit, zip_url}} <- get_tools_zip_url(release_url),
         {:ok, zip_binary} <- get_zip(zip_url),
         :ok <- install_zip(install_dir, zip_binary) do
      fun = fn {:zip_file, dir, _info, _, _, _} ->
        [_ | rest] = Path.split(to_string(dir))
        List.first(rest) == "farmware_tools"
      end

      case :zip.extract(zip_binary, [:memory, file_filter: fun]) do
        {:ok, list} when is_list(list) ->
          Enum.each(list, fn {filename, data} ->
            out_file =
              Path.join([install_dir, "farmware_tools", Path.basename(to_string(filename))])

            File.write!(out_file, data)
          end)

        {:error, reason} ->
          raise(reason)
      end

      :ok
    end
  end

  def get_tools_zip_url(release_url) do
    case get(release_url) do
      {:ok, {{_, 200, _}, _, msg}} ->
        release = JSON.decode!(msg)
        release_commit = release["target_commitish"]
        {:ok, {release_commit, release["zipball_url"]}}

      {:ok, {{_, _, _}, _, msg}} ->
        case JSON.decode(msg) do
          {:ok, %{"message" => message}} -> {:error, message}
          _ -> {:error, msg}
        end

      error ->
        error
    end
  end

  defp get(url) do
    FarmbotTelemetry.HTTP.request(:get, {to_charlist(url), httpc_headers()}, [], httpc_options())
  end

  defp httpc_options, do: [body_format: :binary]
  defp httpc_headers, do: [{'user-agent', 'farmbot-os'}]

  def install_dir(%FWI{} = fwi) do
    install_dir(fwi.manifest)
  end

  def install_dir(%Manifest{package: package}) do
    dir = Path.join(@install_dir, package)
    File.mkdir_p!(dir)
    dir
  end

  defp error_log(%FWI{manifest: %{package: package}}, msg) do
    Logger.error("Farmware #{package} " <> msg)
  end

  defp error_log(%FWI{}, msg) do
    Logger.error("Farmware " <> msg)
  end

  defp success_log(%FWI{manifest: %{package: package}}, msg) do
    Logger.info("Farmware #{package} " <> msg)
  end

  defp success_log(%FWI{}, msg) do
    Logger.info("Farmware " <> msg)
  end
end
