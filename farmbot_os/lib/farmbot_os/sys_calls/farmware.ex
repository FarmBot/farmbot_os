defmodule FarmbotOS.SysCalls.Farmware do
  require Logger
  alias FarmbotCeleryScript.AST
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

  def execute_script(farmware_name, env) do
    with {:ok, manifest} <- lookup_manifest(farmware_name),
         {:ok, runtime} <- FarmwareRuntime.start_link(manifest, env),
         monitor <- Process.monitor(runtime),
         :ok <- loop(farmware_name, runtime, monitor, {nil, nil}),
         :ok <- ImageUploader.force_checkup() do
      :ok
    else
      {:error, {:already_started, _pid}} ->
        {:error, "Farmware #{farmware_name} is already running"}

      {:error, reason} when is_binary(reason) ->
        _ = ImageUploader.force_checkup()
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

  defp loop(farmware_name, runtime, monitor, {ref, label}) do
    receive do
      {:DOWN, ^monitor, :process, ^runtime, :normal} ->
        :ok

      {:step_complete, ^ref, :ok} ->
        Logger.debug("ok for #{label}")
        response = %AST{kind: :rpc_ok, args: %{label: label}, body: []}
        true = FarmwareRuntime.rpc_processed(runtime, response)
        loop(farmware_name, runtime, monitor, {nil, nil})

      {:step_complete, ^ref, {:error, reason}} ->
        Logger.debug("error for #{label}")
        explanation = %AST{kind: :explanation, args: %{message: reason}}
        response = %AST{kind: :rpc_error, args: %{label: label}, body: [explanation]}
        true = FarmwareRuntime.rpc_processed(runtime, response)
        loop(farmware_name, runtime, monitor, {nil, nil})

      msg ->
        {:error, "unhandled message: #{inspect(msg)} in state: #{inspect({ref, label})}"}
    after
      500 ->
        if is_reference(ref) do
          Logger.info("Already processing a celeryscript request: #{label}")
          loop(farmware_name, runtime, monitor, {ref, label})
        else
          case FarmwareRuntime.process_rpc(runtime) do
            {:ok, %{args: %{label: label}} = rpc} ->
              ref = make_ref()
              Logger.debug("executing rpc: #{inspect(rpc)}")
              FarmbotCeleryScript.execute(rpc, ref)
              loop(farmware_name, runtime, monitor, {ref, label})

            {:error, :no_rpc} ->
              loop(farmware_name, runtime, monitor, {ref, label})
          end
        end
    end
  end
end
