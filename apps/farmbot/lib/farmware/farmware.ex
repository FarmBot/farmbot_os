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
  alias Farmware.FarmScript
  alias Farmware.Tracker
  alias Farmbot.BotState.ProcessTracker, as: PT
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
  @spec install(binary) :: map | no_return
  @lint {Credo.Check.Refactor.ABCSize, false}
  def install(manifest_url) do
    Logger.info "Getting Farmware Manifest"
    {manifest, json} = Manifest.get!(manifest_url).body
    path = FS.path() <> "/farmware/#{manifest[:package]}"

    raise_if_exists(path, manifest)

    Logger.info "Getting Farmware Package"
    zip_file_path = Downloader.run(manifest[:zip], "/tmp/#{manifest[:package]}.zip")
    Logger.info "Unpacking Farmware Package"

    FS.transaction fn() ->
      Logger.info "Installing farmware!"
      File.mkdir!(path)
      unzip_file(zip_file_path, path)
      File.write(path <> "/manifest.json", json)
    end, true

    File.rm! "/tmp/#{manifest[:package]}.zip"
    Logger.info "Validating Farmware package"
    case File.read(path <> "/manifest.json") do
      {:ok, _contents} ->
        Logger.info ">> is installing Farmware: #{manifest[:package]}"
        PT.register(:farmware, manifest[:package], manifest[:package])
        manifest
      _ ->
        Logger.info "invalid farmware package!"
        FS.transaction fn() ->
          File.rm_rf!(path)
        end
        raise "Not valid Farmware!"
    end
  end
  _ = @lint # HACK(Connor) fix credo compiler warning

  @doc """
    Uninstalls a Farmware package
  """
  @spec uninstall(binary) :: no_return
  def uninstall(package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      Logger.warn "uninstalling farmware: #{package_name}"
      info = Farmbot.BotState.ProcessTracker.lookup(:farmware, package_name)
      deregister(info)
      FS.transaction fn() ->
        File.rm_rf!(path)
      end
    else
      Logger.error "can not find farmware: #{package_name} to uninstall"
    end
  end

  @spec deregister(map | nil) :: :ok
  defp deregister(nil), do: :ok
  defp deregister(i), do: Farmbot.BotState.ProcessTracker.deregister i.uuid

  @doc """
    Forces an update for a Farmware package
  """
  @spec update(binary) :: no_return
  def update(package_name) do
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      url =
        path <> "/manifest.json"
        |> File.read!
        |> Poison.decode!
        |> Map.get("url")
      uninstall(package_name)
      install(url)
    else
      raise "Could not find Farmware: #{package_name}"
    end
  end

  @doc """
    Starts a farm process. Callback from ProcessTracker
  """
  def start_process(package_name), do: execute(package_name)

  @doc """
    Stops a farm process. Callback from ProcessTracker
  """
  def stop_process(_package_name), do: :ok

  @doc """
    Executes a Farmware Package
    arguments is a list of strings to pass too the script
  """
  @spec execute(binary) :: no_return
  @spec execute(binary, any) :: no_return
  def execute(package_name, envs \\ []) do
    Farmbot.BotState.Monitor.get_state()
    path = FS.path() <> "/farmware/#{package_name}"
    if File.exists?(path) do
      manifest =
        path <> "/manifest.json"
        |> File.read!
        |> Poison.decode!
      exe = manifest["executable"]
      args = manifest["args"]
      %FarmScript{executable: exe,
        args: args, path: path, name: package_name, envs: envs}
      |> Tracker.add()
    else
      msg = ">> Could not find FarmWare: #{package_name}"
      Logger.error msg
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
      Logger.error msg
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
  @lint false # TODO(Connor) nested for/if here
  @spec get_first_party_farmware :: no_return
  def get_first_party_farmware do
    farmwares = HTTPoison.get!("https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json").body
    |> Poison.decode!
    for %{"name" => name, "manifest" => man} <- farmwares do
      if installed?(name) do
        # if its installed already update it
        update(man)
      else
        # if not just install it.
        install(man)
      end
    end
  end

  defp unzip_file(zip_file, path) when is_bitstring(zip_file) do
    cwd = File.cwd!
    File.cd! path
    :zip.unzip(String.to_charlist(zip_file))
    File.cd! cwd
  end
end
