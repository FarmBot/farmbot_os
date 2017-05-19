defmodule Farmware do
  @moduledoc """
    Interface with Farmware.
  """

  defmodule Manifest do
    @moduledoc false
    use HTTPoison.Base
    @schema_location "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/schema.json"

    @spec process_response_body(binary) :: {binary, list}
    def process_response_body(body) do
      f = body
      |> Poison.decode!
      |> validate!()
      |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
      {f, body}
    end

    @spec validate!(map) :: map | no_return
    defp validate!(body) do
      case ExJsonSchema.Validator.validate(schema(), body) do
        :ok -> body
        error -> raise "could not validate package! #{inspect error}"
      end
    end

    @spec schema :: map
    defp schema do
      HTTPoison.get!(@schema_location).body
      |> Poison.decode!
      |> ExJsonSchema.Schema.resolve
    end
  end

  alias Farmbot.System.FS
  alias Farmware.{Tracker, FarmScript}
  alias Farmbot.BotState.ProcessTracker, as: PT
  alias Farmbot.Context
  require Logger

  @behaviour Farmbot.ProcessRunner

  @spec raise_if_exists(binary, map) :: no_return
  defp raise_if_exists(path, manifest) do
    if File.exists?(path) do
      raise "Could not install Farmware! #{manifest[:package]} already exists!"
    end
  end

  @doc """
    Installs a package from a manifest url
  """
  @spec install(Context.t, binary) :: map | no_return
  def install(%Context{} = ctx, manifest_url) do
    Logger.info "Getting Farmware Manifest: #{manifest_url}"
    {manifest, json} = Manifest.get!(manifest_url).body
    path = FS.path() <> "/farmware/#{manifest[:package]}"

    raise_if_exists(path, manifest)

    zip_url = manifest[:zip]
    Logger.info "Getting Farmware Package: #{zip_url}"
    zip_file_path = Downloader.run(zip_url, "/tmp/#{manifest[:package]}.zip")
    Logger.info "Unpacking Farmware Package"

    :ok = do_install_and_cleanup(path, zip_file_path, json, manifest)

    Logger.info "Validating Farmware package"

    if File.exists?(path <> "/manifest.json") do
      register(ctx, manifest)
    else
      error_clean_up(path)
    end
  end

  defp do_install_and_cleanup(path, zip_file_path, json, manifest) do
    FS.transaction fn() ->
      Logger.info "Installing farmware!"
      File.mkdir!(path)
      unzip_file(zip_file_path, path)
      File.write(path <> "/manifest.json", json)
    end, true

    File.rm! "/tmp/#{manifest[:package]}.zip"
  end

  defp error_clean_up(path) do
    Logger.info "invalid farmware package!"
    FS.transaction fn() ->
      File.rm_rf!(path)
    end, true
    raise "Not valid Farmware!"
  end

  defp register(%Context{} = ctx, manifest) do
    Logger.info ">> is installing Farmware: #{manifest[:package]}"
    PT.register(ctx, :farmware, manifest[:package], manifest[:package])
    manifest
  end

  @doc """
    Uninstalls a Farmware package
  """
  @spec uninstall(Context.t, binary) :: no_return
  def uninstall(%Context{} = ctx, package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      Logger.info "uninstalling farmware: #{package_name}", type: :busy
      info = Farmbot.BotState.ProcessTracker.lookup(ctx, :farmware, package_name)
      deregister(ctx, info)
      FS.transaction fn() ->
        File.rm_rf!(path)
      end, true
    else
      msg = "can not find farmware: #{package_name} to uninstall"
      Logger.info msg, type: :error
    end
  end

  @spec deregister(Context.t, map | nil) :: :ok
  defp deregister(%Context{} = _, nil), do: :ok
  defp deregister(%Context{} = ctx, i),
    do: Farmbot.BotState.ProcessTracker.deregister ctx, i.uuid

  @doc """
    Forces an update for a Farmware package
  """
  @spec update(Context.t, binary) :: no_return
  def update(%Context{} = ctx, package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      url =
        path <> "/manifest.json"
        |> File.read!
        |> Poison.decode!
        |> Map.get("url")
      uninstall(ctx, package_name)
      install(ctx, url)
    else
      raise "Could not find Farmware to update! #{package_name}"
    end
  end

  @doc """
    Starts a farm process. Callback from ProcessTracker
  """
  def start_process(%Context{} = ctx, package_name),
    do: execute(ctx, package_name)

  @doc """
    Stops a farm process. Callback from ProcessTracker
  """
  def stop_process(%Context{} = _ctx, _package_name), do: :ok

  @doc """
    Executes a Farmware Package
    arguments is a list of strings to pass too the script
  """
  @spec execute(Context.t, binary) :: no_return
  @spec execute(Context.t, binary, any) :: no_return
  def execute(%Context{} = ctx, package_name, envs \\ []) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      manifest =
        path <> "/manifest.json"
        |> File.read!
        |> Poison.decode!
      exe = manifest["executable"]
      args = manifest["args"]
      item = %FarmScript{executable: exe,
                         args: args,
                         path: path,
                         name: package_name,
                         envs: envs}
      Tracker.add(ctx, item)
    else
      msg = ">> Could not find FarmWare: #{package_name}"
      Logger.info msg, type: :error
      raise msg
    end
  end

  @spec info(String.t) :: map | no_return
  def info(package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      path <> "/manifest.json"
      |> File.read!
      |> Poison.decode!
    else
      msg = ">> Could not find FarmWare: #{package_name}"
      Logger.info msg, type: :error
      raise msg
    end
  end

  @doc """
    Checks if a package is installed
  """
  @spec installed?(binary) :: boolean
  def installed?(package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    File.exists?(path)
  end

  @doc """
    Lists all installed Farmware Packages
  """
  @spec list :: [binary]
  def list, do: File.ls!(FS.path() <> "/farmware/")

  @doc """
    Downloads and updates first party farmwares.
  """
  @spec get_first_party_farmware(Context.t) :: no_return
  def get_first_party_farmware(%Context{} = ctx) do
    farmwares = HTTPoison.get!("https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json").body
    |> Poison.decode!
    for %{"name" => name, "manifest" => manifest} <- farmwares do
      maybe_install(ctx, name, manifest)
    end
  end

  defp maybe_install(%Context{} = ctx, name, manifest) do
    if installed?(name) do
      # if its installed already update it
      update(ctx, name)
    else
      # if not just install it.
      install(ctx, manifest)
    end
  end

  defp unzip_file(zip_file, path) when is_bitstring(zip_file) do
    cwd = File.cwd!
    File.cd! path
    :zip.unzip(String.to_charlist(zip_file))
    File.cd! cwd
  end
end
