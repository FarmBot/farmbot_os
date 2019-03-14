defmodule FarmbotOS.SysCalls.ExecuteScript do
  require Logger
  alias FarmbotCeleryScript.{AST, Scheduler}
  alias FarmbotCore.{Asset, FarmwareRuntime}

  def execute_script(farmware_name, env) do
    with {:ok, manifest} <- lookup(farmware_name),
         {:ok, runtime} <- FarmwareRuntime.start_link(manifest, env) do
      monitor = Process.monitor(runtime)
      IO.inspect(runtime, label: "runtime pid")
      loop(farmware_name, runtime, monitor, {nil, nil})
    else
      {:error, {:already_started, _pid}} ->
        {:error, "Farmware #{farmware_name} is already runtime"}

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

  defp loop(farmware_name, runtime, monitor, {ref, label}) do
    receive do
      {:DOWN, ^monitor, :process, ^runtime, :normal} ->
        :ok

      {Scheduler, ^ref, :ok} ->
        response = %AST{kind: :rpc_ok, args: %{label: label}, body: []}
        true = FarmwareRuntime.rpc_processed(runtime, response)
        loop(farmware_name, runtime, monitor, {nil, nil})

      {Scheduler, ^ref, {:error, reason}} ->
        explaination = %AST{kind: :explaination, args: %{message: reason}}
        response = %AST{kind: :rpc_error, args: %{label: label}, body: [explaination]}
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
              {:ok, ref} = Scheduler.schedule(rpc)
              loop(farmware_name, runtime, monitor, {ref, label})

            {:error, :no_rpc} ->
              loop(farmware_name, runtime, monitor, {ref, label})
          end
        end
    end
  end
end
