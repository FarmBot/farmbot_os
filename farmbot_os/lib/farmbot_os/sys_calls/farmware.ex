defmodule FarmbotOS.SysCalls.Farmware do
  require Logger
  # alias FarmbotCeleryScript.AST
  alias FarmbotCore.{Asset, AssetSupervisor, FarmwareRuntime}
  alias FarmbotExt.API.ImageUploader

  def update_farmware(farmware_name) do
    with {:ok, installation} <- lookup_installation(farmware_name) do
      AssetSupervisor.cast_child(installation, :update)
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}
    end
  end

  def lookup_manifest(farmware_name) do
    case Asset.get_farmware_manifest(farmware_name) do
      nil -> {:error, "#{farmware_name} farmware not installed"}
      manifest -> {:ok, manifest}
    end
  end

  def lookup_installation(farmware_name) do
    case Asset.get_farmware_installation(farmware_name) do
      nil -> {:error, "#{farmware_name} farmware not installed"}
      farmware -> {:ok, farmware}
    end
  end

  # Entry point to starting a farmware
  def execute_script(farmware_name, env) do
    with {:ok, manifest} <- lookup_manifest(farmware_name),
         {:ok, runtime} <- FarmwareRuntime.start_link(manifest, env),
         :ok <- loop(runtime),
         :ok <- ImageUploader.force_checkup() do
      :ok
    else
      {:error, {:already_started, pid}} ->
        FarmwareRuntime.stop(pid)
        execute_script(farmware_name, env)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def loop(farmware_runtime) do
    receive do
      {:error, :farmware_exit} ->
        :ok

      {:error, reason} ->
        {:error, inspect(reason)}
    after
      30_000 ->
        Logger.debug("Force stopping farmware: #{inspect(farmware_runtime)}")
        FarmwareRuntime.stop(farmware_runtime)
        :ok
    end
  end
end
