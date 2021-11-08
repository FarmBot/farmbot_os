defmodule FarmbotOS.SysCalls.Farmware do
  @moduledoc false

  require FarmbotOS.Logger
  alias FarmbotOS.FarmwareRuntime
  alias FarmbotOS.API.ImageUploader
  @farmware_timeout 1_200_000

  # Entry point to starting a farmware
  def execute_script(farmware_name, env) do
    fs = FarmbotOS.BotState.FileSystem
    if Process.whereis(fs), do: send(fs, :timeout)

    with {:ok, runtime} <- FarmwareRuntime.start_link(farmware_name, env),
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

    FarmbotOS.Logger.info(2, msg)
    FarmwareRuntime.stop(farmware_runtime)
    :ok
  end
end
