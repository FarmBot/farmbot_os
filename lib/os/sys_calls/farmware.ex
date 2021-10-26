defmodule FarmbotOS.SysCalls.Farmware do
  @moduledoc false

  require FarmbotCore.Logger
  alias FarmbotCore.FarmwareRuntime
  alias FarmbotExt.API.ImageUploader
  @farmware_timeout 1_200_000

  def lookup_manifest(farmware_name) do
    case FarmwareRuntime.get_farmware_manifest(farmware_name) do
      nil -> {:error, "#{farmware_name} farmware not installed"}
      manifest -> {:ok, manifest}
    end
  end

  def lookup_installation(farmware_name) do
    case FarmwareRuntime.get_farmware_installation(farmware_name) do
      nil -> {:error, "#{farmware_name} farmware not installed"}
      farmware -> {:ok, farmware}
    end
  end

  # Entry point to starting a farmware
  def execute_script(farmware_name, env) do
    fs = FarmbotCore.BotState.FileSystem
    if Process.whereis(fs), do: send(fs, :timeout)

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
      {:error, :farmware_exit} -> :ok
      {:error, reason} -> {:error, inspect(reason)}
    after
      @farmware_timeout -> farmware_timeout(farmware_runtime)
    end
  end

  def farmware_timeout(farmware_runtime) do
    time = @farmware_timeout / 1_000 / 60
    runtime = inspect(farmware_runtime)
    msg = "Farmware did not exit after #{time} minutes. Terminating #{runtime}"

    FarmbotCore.Logger.info(2, msg)
    FarmwareRuntime.stop(farmware_runtime)
    :ok
  end
end
