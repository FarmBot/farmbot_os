defmodule FarmbotOS.SysCalls.ExecuteScript do
  alias FarmbotCore.{Asset, FarmwareRuntime}

  def execute_script(farmware_name, env) do
    with {:ok, manifest} <- lookup(farmware_name),
         {:ok, runtime} <- FarmwareRuntime.start_link(manifest, env) do
    else
      {:error, {:already_started, _pid}} ->
        {:error, "Farmware #{farmware_name} is already running"}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}
    end
  end

  def lookup(farmware_name) do
    case Asset.get_farmware_manifest(farmware_name) do
      nil -> {:error, "farmware not installed"}
      manifest -> {:ok, manifest}
    end
  end
end
