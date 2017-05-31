defmodule Farmbot.Farmware.Runtime do
  @moduledoc """
    Executes a farmware
  """
  use Farmbot.DebugLog, name: FarmwareRuntime
  alias Farmbot.{Farmware, Context, BotState, Auth, CeleryScript}
  alias Farmware.RuntimeError, as: FarmwareRuntimeError
  alias Farmbot.Farmware.Manager
  require Logger

  @clean_up_timeout 30000

  @doc """
    Executes a Farmware inside a safe sandbox
  """
  @spec execute(Context.t, Farmware.t) :: Context.t | no_return
  def execute(%Context{} = ctx, %Farmware{} = fw) do
    debug_log "Starting execution of #{inspect fw}"
    env        = environment(ctx)
    exec       = System.find_executable(fw.executable)
    port       = Port.open({:spawn_executable, exec}, [:stream,
                                                       :binary,
                                                       :exit_status,
                                                       :hide,
                                                       :use_stdio,
                                                       :stderr_to_stdout,
                                                       args: fw.args,
                                                       env: env ])
    %Context{} = new_ctx = handle_port(ctx, fw, port)
    new_ctx
  end

  defp handle_port(%Context{} = ctx, %Farmware{} = fw, port) do
    receive do
      {^port, {:exit_status, 0}} ->
        Logger.info ">> [#{fw.name}] completed!"
        ctx
      {^port, {:exit_status, s}} ->
        raise FarmwareRuntimeError, message: "#{fw.name} completed with errors! (#{s})"
      {^port, {:data, data}} ->
        handle_script_output(ctx, fw, data, port)
      after
        @clean_up_timeout ->
          :ok = maybe_kill_port(port)
          raise FarmwareRuntimeError, message: "#{fw.name} time out"
    end
  end

  @spec handle_script_output(Context.t, Farmware.t, binary, port) :: Context.t
  defp handle_script_output(%Context{} = ctx, fw, data, port) do
    result = Poison.decode(String.trim(data))
    case result do
      {:ok, json_map} ->
        ctx |> execute_celery_script(json_map) |> handle_port(fw, port)
      {:error, _} ->
        debug_log("MALFORMED FARMWARE INPUT. EXITING....")
        :ok = maybe_kill_port(port)
        ctx
    end
  end

  @spec execute_celery_script(Context.t, map) :: Context.t | no_return
  defp execute_celery_script(%Context{} = ctx, json_map) do
    ast = CeleryScript.Ast.parse(json_map)
    CeleryScript.Command.do_command(ast, ctx)
  end

  @spec maybe_kill_port(port) :: :ok
  defp maybe_kill_port(port) do
    debug_log "trying to kill port: #{inspect port}"
    port_info  = Port.info(port)
    if port_info do
      os_pid   = Keyword.get(port_info, :os_pid)
      {0, ""}  = System.cmd("kill", ["-9", os_pid])
      :ok
    else
      debug_log("Port info was nil.")
      :ok
    end
  end

  defp environment(%Context{} = ctx) do
    envs = BotState.get_user_env(ctx)
    wow  = Auth.get_token(ctx.auth)
    {:ok, %Farmbot.Token{} = tkn} = wow
    envs = Map.put(envs, "API_TOKEN", tkn)
    Enum.map(envs, fn({key, val}) ->
      {to_erl_safe(key), to_erl_safe(val)}
    end)
  end

  defp to_erl_safe(%Farmbot.Token{encoded: enc}), do: to_erl_safe(enc)
  defp to_erl_safe(binary) when is_binary(binary), do: to_charlist(binary)
  defp to_erl_safe(map) when is_map(map), do: map |> Poison.encode! |> to_erl_safe()
  defp to_erl_safe(number) when is_number(number), do: number
end
