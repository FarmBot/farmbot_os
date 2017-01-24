defmodule Farmware do
  @moduledoc """
    Interface with Farmware.
  """

  defmodule Manifest do
    @moduledoc false
    # This will need to be hosted somewhere first party.
    @schema_location "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/schema.json"
    use HTTPoison.Base

    def process_response_body(body) do
      f = body
      |> Poison.decode!
      |> validate!()
      |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
      {f, body}
    end

    defp validate!(body) do
      case ExJsonSchema.Validator.validate(schema(), body) do
        :ok -> body
        error -> raise "could not validate package! #{inspect error}"
      end
    end

    defp schema() do
      HTTPoison.get!(@schema_location).body
      |> Poison.decode!
      |> ExJsonSchema.Schema.resolve
    end
  end

  alias Farmbot.System.FS
  alias Farmware.FarmScript
  alias Farmware.Tracker
  require Logger

  @doc """
    Installs a package from a manifest url
  """
  def install(manifest_url) do
    Logger.debug "Getting Farmware Manifest"
    {manifest, json} = Manifest.get!(manifest_url).body
    path = FS.path() <> "/farmware/#{manifest[:package]}"

    if File.exists?(path) do
      raise "Could not install Farmware! #{manifest[:package]} already exists!"
    end

    Logger.debug "Getting Farmware Package"
    zip_file_path = Downloader.run(manifest[:zip], "/tmp/#{manifest[:package]}.zip")
    Logger.debug "Unpacking Farmware Package"

    FS.transaction fn() ->
      File.mkdir!(path)
      unzip_file(zip_file_path, path)
      File.write(path <> "/manifest.json", json)
    end

    File.rm! "/tmp/#{manifest[:package]}.zip"
    Logger.debug "Validating Farmware package"
    case File.read(path <> "/manifest.json") do
      {:ok, _contents} ->
        Logger.debug ">> is installing Farmware: #{manifest[:package]}"
        manifest
      _ ->
        Logger.debug "invalid farmware package!"
        FS.transaction fn() ->
          File.rm_rf!(path)
        end
        raise("Not valid Farmware!")
    end
  end

  @doc """
    Uninstalls a Farmware package
  """
  def uninstall(package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      Logger.warn "uninstalling farmware: #{package_name}"
      File.rm_rf!(path)
    else
      Logger.error "can not find farmware: #{package_name} to uninstall"
    end
  end

  @doc """
    Forces an update for a Farmware package
  """
  def update(package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      url =
        File.read!(path <> "/manifest.json")
        |> Poison.decode!
        |> Map.get("url")
      uninstall(package_name)
      install(url)
    else
      raise "Could not find Farmware: #{package_name}"
    end
  end

  @doc """
    Executes a Farmware Package
  """
  def execute(package_name) do
    Farmbot.BotState.Monitor.get_state()
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      manifest =
        File.read!(path <> "/manifest.json")
        |> Poison.decode!
      exe = manifest["executable"]
      args = manifest["args"]
      %FarmScript{executable: exe, args: args, path: path, name: package_name}
      |> Tracker.add
    else
      raise "Could not find Farmware: #{package_name}"
    end
  end

  @doc """
    Lists all installed Farmware Packages
  """
  def list, do: File.ls!(FS.path() <> "/farmware/")

  defp unzip_file(zip_file, path) when is_bitstring(zip_file) do
    cwd = File.cwd!
    File.cd! path
    :zip.unzip(String.to_charlist(zip_file))
    File.cd! cwd
  end
end
