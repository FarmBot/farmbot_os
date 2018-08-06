defmodule Farmbot.OS.IOLayer.Farmware do
  require Farmbot.Logger
  alias Farmbot.OS.IOLayer.Farmware.Server

  @fpf_url "https://raw.githubusercontent.com/FarmBot-Labs/farmware_manifests/master/manifest.json"

  def first_party(_args, []) do
    case Farmbot.Farmware.Installer.add_repo(@fpf_url) do
      {:ok, _} -> do_sync_repo()
      {:error, :repo_already_exists} -> do_sync_repo()
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp do_sync_repo do
    case Farmbot.Farmware.Installer.sync_repo(@fpf_url) do
      {:ok, _} -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def install(%{url: url}, []) do
    case Farmbot.Farmware.Installer.install(url) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def update(%{package: name}, []) do
    case Farmbot.Farmware.lookup(name) do
      {:ok, fw} -> install(%{url: fw.url}, [])
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def remove(%{package: name}, []) do
    case Farmbot.Farmware.lookup(name) do
      {:ok, fw} -> do_uninstall(fw)
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def do_uninstall(%Farmbot.Farmware{} = fw) do
    case Farmbot.Farmware.Installer.uninstall(fw) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  def execute(%{package: name}, []) do
    case Farmbot.Farmware.lookup(name) do
      {:ok, fw} ->
        do_execute(fw)
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  # 1)  Check if Farmware is already running
  # 1a) Farmware isn't running - start it.
  # 1b) Farmware is running - continute.
  # 2)  check if there is a rpc_request to process.
  # 2a) there is a request - queue it
  # 2b) there is not a request - continue.
  # 3)  check if server is still alive
  # 3a) The server is still alive - continue
  # 3b) the server is not still alive - exit
  def do_execute(fw) do
    case Server.lookup(fw) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
    |> Server.is_alive?()
    |> case do
      true ->
        case Server.get_request(pid) do
          {:ok, request} -> {:ok, request}
          nil -> {:ok, %Farmbot.CelerScript.AST.new(:rpc_request, %{args: "noop"}, [])}
        end
    end
  end
end
