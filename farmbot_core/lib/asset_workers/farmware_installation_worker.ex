defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FarmwareInstallation do
  use GenServer
  alias Farmbot.Asset.Repo
  alias Farmbot.Asset.FarmwareInstallation, as: FWI
  require Farmbot.Logger
  config = Application.get_env(:farmbot_core, __MODULE__)
  @install_dir config[:install_dir] || Mix.raise("Missing Install Dir")
  @error_retry_time_ms config[:error_retry_time_ms] || 30_000
  @manifest_name "manifest.json"

  def start_link(fwi) do
    GenServer.start_link(__MODULE__, [fwi])
  end

  def init([fwi]) do
    {:ok, fwi, 0}
  end

  def handle_info(:timeout, %FWI{manifest: nil} = fwi) do
    Farmbot.Logger.busy 3, "Installing Farmware from url: #{fwi.url}"
    with {:ok, %{} = manifest} <- get_manifest_json(fwi),
         %{valid?: true} = changeset <- FWI.changeset(fwi, %{manifest: manifest}),
         {:ok, %FWI{} = updated} <- Repo.update(changeset),
         {:ok, zip_binary} <- get_zip(updated),
         :ok <- install_zip(updated, zip_binary),
         :ok <- write_manifest(updated) do
      # TODO(Connor) -> No reason to keep this process alive?
      {:noreply, fwi}
    else
      error ->
        error_log(fwi, "failed to download Farmware manifest: #{inspect(error)}")
        {:noreply, fwi, @error_retry_time_ms}
    end
  end

  def handle_info(:timeout, %FWI{} = fwi) do
    with {:ok, %{} = i_manifest} <- load_manifest_json(fwi),
         %{valid?: true} = d_changeset <- FWI.changeset(fwi, %{manifest: i_manifest}),
         %FWI{} = dirty <- Ecto.Changeset.apply_changes(d_changeset),
         {:ok, n_manifest} <- get_manifest_json(fwi),
         %{valid?: true} = n_changeset <- FWI.changeset(fwi, %{manifest: n_manifest}),
         {:ok, %FWI{} = updated} <- Repo.update(n_changeset) do
      maybe_update(dirty, updated)
    else
      error ->
        error_log(fwi, "failed to check for updates: #{inspect(error)}")

        {:noreply, fwi, @error_retry_time_ms}
    end
  end

  def maybe_update(%FWI{} = installed_fwi, %FWI{} = updated) do
    case Version.compare(installed_fwi.manifest.version, updated.manifest.version) do
      # Installed is newer than remote.
      :gt ->
        success_log(updated, "up to date.")
        {:noreply, updated}

      # No difference between installed and remote.
      :eq ->
        success_log(updated, "up to date.")
        {:noreply, updated}

      # Installed version is older than remote
      :lt ->
        success_log(updated, "update available.")

        with {:ok, zip_binary} <- get_zip(updated),
             :ok <- install_zip(updated, zip_binary),
             :ok <- write_manifest(updated) do
          {:noreply, updated}
        else
          er ->
            error_log(updated, "update failed: #{inspect(er)}")
            {:noreply, updated, @error_retry_time_ms}
        end
    end
  end

  def get_manifest_json(%FWI{url: url}) do
    with {:ok, {{_, 200, _}, _headers, data}} <- get(url) do
      Farmbot.JSON.decode(data)
    end
  end

  def load_manifest_json(%FWI{manifest: %{}} = fwi) do
    with {:ok, data} <- File.read(Path.join(install_dir(fwi), @manifest_name)) do
      Farmbot.JSON.decode(data)
    end
  end

  def get_zip(%FWI{manifest: %{zip: url}}) do
    with {:ok, {{_, 200, _}, _headers, zip_binary}} <- get(url),
         {:ok, zip} <- :zip.zip_open(zip_binary, [:memory]),
         :ok <- :zip.zip_close(zip) do
      {:ok, zip_binary}
    end
  end

  def install_zip(%FWI{} = fwi, binary) when is_binary(binary) do
    with {:ok, _} <- :zip.extract(binary, [{:cwd, install_dir(fwi)}]) do
      :ok
    end
  end

  defp write_manifest(%FWI{manifest: manifest} = fwi) do
    json = FWI.Manifest.view(manifest) |> Farmbot.JSON.encode!()

    fwi
    |> install_dir()
    |> Path.join(@manifest_name)
    |> File.write(json)
  end

  def get(url) do
    :httpc.request(:get, {to_charlist(url), []}, [], httpc_options())
  end

  defp httpc_options, do: [body_format: :binary]

  def install_dir(%FWI{manifest: %{package: package}}) do
    dir = Path.join(@install_dir, package)
    File.mkdir_p!(dir)
    dir
  end

  defp error_log(%FWI{manifest: %{package: package}}, msg) do
    Farmbot.Logger.error(3, "Farmware #{package} " <> msg)
  end

  defp error_log(%FWI{}, msg) do
    Farmbot.Logger.error(3, "Farmware " <> msg)
  end

  defp success_log(%FWI{manifest: %{package: package}}, msg) do
    Farmbot.Logger.success(3, "Farmware #{package} " <> msg)
  end

  defp success_log(%FWI{}, msg) do
    Farmbot.Logger.success(3, "Farmware " <> msg)
  end
end
