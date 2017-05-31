defmodule Farmbot.Farmware.Installer do
  @moduledoc """
    Handles the installing and uninstalling of packages
  """

  alias Farmbot.{Context, Farmware, System}
  alias Farmware.Manager
  alias Farmware.Installer.Repository
  alias System.FS
  use Farmbot.DebugLog
  @version Mix.Project.config[:version]

  @doc """
    Installs a farmware.
    Does not register to the Manager.
  """
  @spec install!(Context.t, binary) :: Farmware.t | no_return
  def install!(%Context{} = ctx, url) do
    :ok             = ensure_dirs!()
    schema          = ensure_schema!()
    %{body: binary} = Farmbot.HTTP.get!(ctx, url)
    json            = Poison.decode!(binary)
    :ok             = validate_json!(schema, json)
    debug_log "Installing a Farmware from: #{url}"
    print_json_debug_info(json)
    ensure_correct_version!(json)
    package_path = "#{package_path()}/#{json["package"]}"
    dl_path      = Farmbot.HTTP.download_file!(ctx, json["zip"], "/tmp/#{json["package"]}.zip")
    FS.transaction fn() ->
      File.mkdir_p!(package_path)
      unzip! dl_path, package_path
      File.write! "#{package_path}/manifest.json", binary
    end, true
    fw = Farmware.new(json)
    debug_log "Installed new Farmware: #{inspect fw}"
    fw
  end

  defp ensure_correct_version!(%{"min_os_version_major" => major}) do
    ver_int = @version |> String.first() |> String.to_integer
    if major > ver_int do
       raise "Version mismatch! Farmbot is: #{ver_int} Farmware requires: #{major}"
     else
       :ok
    end
  end

  defp print_json_debug_info(json) do
    stuff = Enum.reduce(json, "", fn({key, val}, acc) ->
      "\t#{key} => #{inspect val}\n" <> acc
    end)
    debug_log "Json: \n#{stuff}"

  end

  @doc """
    Uninstalls a farmware.
    Does no unregister from the Manager.
  """
  @spec uninstall!(Context.t, Farmware.t) :: :ok | no_return
  def uninstall!(%Context{} = _ctx, %Farmware{} = fw) do
    :ok    = ensure_dirs!()
    debug_log "Uninstalling a Farmware from: #{inspect fw}"
    package_path = "#{package_path()}/#{fw.name}"
    FS.transaction fn() ->
      File.rm_rf!(package_path)
    end, true
  end

  @doc """
    Enables a repo to be synced on bootup
  """
  @spec enable_repo!(Context.t, atom) :: :ok | no_return
  def enable_repo!(%Context{} = ctx, module) when is_atom(module) do
    debug_log "repo: #{module} is syncing"
    # make sure we have a valid repository here.
    ensure_module!(module)
    :ok             = ensure_dirs!()
    url             = module.url()
    %{body: binary} = Farmbot.HTTP.get!(ctx, url)
    json            = Poison.decode!(binary)
    repository      = Repository.validate!(json)

    :ok = ensure_not_synced!(module)
    # do the installs
    for entry <- repository.entries do
      :ok = Manager.install!(ctx, entry.manifest)
    end

    :ok = set_synced!(module)
  end

  @doc """
    Lists all the farmwares
  """
  @spec list_installed! :: [Farmware.t]
  def list_installed! do
    ensure_dirs!()
    dirs = File.ls! package_path()
    try do
      Enum.map(dirs, fn(dir) ->
        package_dir = "#{package_path()}/#{dir}"
        json = File.read!("#{package_dir}/manifest.json") |> Poison.decode!
        ensure_correct_version!(json)
        Farmware.new(json)
      end)
    rescue
      e ->
        FS.transaction fn() ->
          File.rm_rf!(package_path())
        end, true
        reraise e, Elixir.System.stacktrace()
    end
  end

  defp ensure_dirs! do
    ensure_dir! path()
    ensure_dir! repo_path()
    ensure_dir! package_path()
  end

  defp ensure_dir!(path) do
    debug_log "Ensuring dir: #{inspect path}"
    unless File.exists?(path) do
      FS.transaction fn() ->
        File.mkdir_p!(path)
      end, true
    end
    :ok
  end

  defp ensure_not_synced!(module) when is_atom(module) do
    path = "#{repo_path()}/#{module}"
    if File.exists?(path) do
      raise "Could not sync #{module} is already synced up!"
    else
      :ok
    end
  end

  defp set_synced!(module) when is_atom(module) do
     path = "#{repo_path()}/#{module}"
     FS.transaction fn() ->
       File.write! path, "#{:os.system_time}"
     end, true
     debug_log "#{module} was synced"
     :ok
  end

  defp ensure_module!(module) do
    {:module, real} = Code.ensure_loaded(module)
    if function_exported?(real, :url, 0) do
      debug_log "repo #{module} is loaded"
      :ok
    else
      raise "Could not load repository: #{inspect module}"
    end
  end

  defp path, do: "#{FS.path()}/farmware"
  defp repo_path, do: "#{path()}/repos"
  defp package_path, do: "#{path()}/packages"

  defp unzip!(zip_file, path) when is_bitstring(zip_file) do
    debug_log "Unzipping #{zip_file} to #{path}"
    cwd = File.cwd!
    File.cd! path
    :zip.unzip(String.to_charlist(zip_file))
    debug_log "Done unzipping #{zip_file} to #{path}"
    File.cd! cwd
  end

  @doc """
    Ensures the schema has been resolved.
  """
  def ensure_schema! do
    schema_path() |> File.read!() |> Poison.decode!() |> ExJsonSchema.Schema.resolve()
  end

  defp schema_path, do: "#{:code.priv_dir(:farmbot)}/static/farmware_schema.json"

  defp validate_json!(schema, json) do
    case ExJsonSchema.Validator.validate(schema, json) do
      :ok              -> :ok
      {:error, reason} ->  raise "Error parsing manifest #{inspect reason}"
    end
  end

end
