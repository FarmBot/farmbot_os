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
    handle_port(ctx, fw, port)
  end

  defp handle_port(%Context{} = ctx, %Farmware{} = fw, port) do
    receive do
      {^port, {:exit_status, 0}} ->
        Logger.info ">> [#{fw.name}] completed!"
      {^port, {:exit_status, s}} ->
        Logger.info ">> [#{fw.name}] completed with errors! (#{s})", type: :error
      {^port, {:data, data}} ->
        handle_script_output(ctx, fw, data, port)
      after
        @clean_up_timeout ->
          Logger.error ">> [#{fw.name}] Timed out"
          kill_port(port)
    end
  end

  defp handle_script_output(ctx, fw, data, port) do
    result = Poison.decode(String.trim(data))
    case result do
      {:ok, json} ->
        do_stuff(ctx, json)
        handle_port(ctx, fw, port)
      {:error, _} ->
        debug_log("MALFORMED FARMWARE INPUT. EXITING....")
        kill_port(port)
    end
  end

  def do_stuff(context, json) do
    ast = CeleryScript.Ast.parse(json)
    CeleryScript.Command.do_command(ast, context)
  end

  defp kill_port(port) do
    port_info  = Port.info(port)
    if port_info do
      os_pid   = Keyword.get(port_info, :os_pid)
      {0, _}   = System.cmd("kill", ["-9", os_pid])
    else
      debug_log("PORT_INFO WAS NIL")
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
end
