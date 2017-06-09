defmodule Farmbot.Farmware.Runtime do
  @moduledoc """
    Executes a farmware
  """
  use Farmbot.DebugLog, name: FarmwareRuntime
  alias Farmbot.{Farmware, Context, BotState, Auth, CeleryScript}
  alias Farmware.RuntimeError, as: FarmwareRuntimeError
  require Logger

  defmodule State do
    @moduledoc false
    defstruct [:uuid, :port, :farmware, :context, :output]

    @typedoc false
    @type t :: %__MODULE__{
      uuid: binary,
      port: port,
      farmware: Farmware.t,
      context: Context.t,
      output: [binary]
    }
  end

  @typedoc false
  @type state :: State.t

  @clean_up_timeout 30_000

  @doc """
    Executes a Farmware inside a safe sandbox
  """
  @spec execute(Context.t, Farmware.t) :: Context.t | no_return
  def execute(%Context{} = ctx, %Farmware{} = fw) do
    debug_log "Starting execution of #{inspect fw}"
    debug_log "Starting execution of: #{inspect fw}"
    uuid       = Nerves.Lib.UUID.generate()
    env        = environment(ctx, uuid)
    exec       = lookup_exec_or_raise(fw.executable)
    cwd        = File.cwd!

    case File.cd(fw.path) do
      :ok -> :ok
      err ->
        raise FarmwareRuntimeError,
          message: "could not change directory: #{inspect err}"
    end

    port = Port.open({:spawn_executable, exec},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout,
       args: fw.args,
       env: env ])

    state = %State{
      uuid:     uuid,
      port:     port,
      farmware: fw,
      context:  ctx,
      output:   []
    }

    %Context{} = new_ctx = handle_port(state)
    File.cd!(cwd)
    new_ctx
  end

  defp lookup_exec_or_raise(exec) do
    System.find_executable(exec) || raise FarmwareRuntimeError,
      message: "Could not locate #{exec}"
  end

  @spec handle_port(state) :: Context.t | no_return
  defp handle_port(%State{port: port, farmware: fw} = state) do
    receive do
      {^port, {:exit_status, 0}} ->
        Logger.info ">> [#{fw.name}] completed!", type: :success
        state.context
      {^port, {:exit_status, s}} ->
        raise FarmwareRuntimeError, message: "#{fw.name} completed with errors! (#{s})"
      {^port, {:data, data}} ->
        %State{} = new_state = handle_script_output(state, data)
        handle_port(new_state)
      after
        @clean_up_timeout ->
          :ok = maybe_kill_port(port)
          raise FarmwareRuntimeError, message: "#{fw.name} time out"
    end
  end

  @spec handle_script_output(state, binary) :: Context.t | no_return
  defp handle_script_output(%State{} = state, data) do
    <<uuid :: size(288) >> = state.uuid
    case data do
      << ^uuid :: size(288), json :: binary >> ->
        debug_log "going to try to do: #{json}"
        new_context =
          json
            |> String.trim()
            |> Poison.decode!()
            |> CeleryScript.Ast.parse()
            |> CeleryScript.Command.do_command(state.context)
        %{state | context: new_context}
      _data ->
        debug_log("[#{state.farmware.name}] Sent data: #{data}")
        %{state | output: [data | state.output]}
    end
  end

  @spec maybe_kill_port(port) :: :ok
  defp maybe_kill_port(port) do
    debug_log "trying to kill port: #{inspect port}"
    port_info  = Port.info(port)
    if port_info do
      os_pid   = Keyword.get(port_info, :os_pid)
      System.cmd("kill", ["-9", "#{os_pid}"])
      :ok
    else
      debug_log("Port info was nil.")
      :ok
    end
  end

  defp environment(%Context{} = ctx, uuid) do
    envs                          = BotState.get_user_env(ctx)
    {:ok, %Farmbot.Token{} = tkn} = Auth.get_token(ctx.auth)
    envs                          = envs
                                    |> Map.put("API_TOKEN",          tkn)
                                    |> Map.put("BEGIN_CELERYSCRIPT", uuid)
                                    |> Map.put("IMAGES_DIR",         "/tmp/images")
    Enum.map(envs, fn({key, val}) -> {to_erl_safe(key), to_erl_safe(val)} end)
  end

  defp to_erl_safe(%Farmbot.Token{encoded: enc}), do: to_erl_safe(enc)
  defp to_erl_safe(binary) when is_binary(binary), do: to_charlist(binary)
  defp to_erl_safe(map) when is_map(map), do: map |> Poison.encode! |> to_erl_safe()
  defp to_erl_safe(number) when is_number(number), do: number
end
