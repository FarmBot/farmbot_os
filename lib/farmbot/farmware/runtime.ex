defmodule Farmbot.Farmware.Runtime do
  @moduledoc """
    Executes a farmware
  """
  use     Farmbot.DebugLog, name: FarmwareRuntime
  alias   Farmbot.{Farmware, Context, BotState, Auth}
  alias   Farmware.RuntimeError, as: FarmwareRuntimeError
  alias   Farmbot.Farmware.Runtime.HTTPServer.JWT, as: FarmwareJWT
  alias   Farmbot.Farmware.Runtime.HTTPServer

  require Logger

  defmodule State do
    @moduledoc false
    defstruct [:uuid, :port, :farmware, :context, :output, :server]

    @typedoc false
    @type t :: %__MODULE__{
      server:   GenServer.server,
      uuid:     binary,
      port:     port,
      farmware: Farmware.t,
      context:  Context.t,
      output:   [binary]
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
    debug_log "Starting execution of: #{inspect fw}"
    Process.flag(:trap_exit, true)
    uuid          = Nerves.Lib.UUID.generate()
    fw_jwt        = %FarmwareJWT{start_time: Timex.now() |> DateTime.to_iso8601()}
    http_port     = lookup_port()
    env           = environment(ctx, fw_jwt, http_port)
    exec          = lookup_exec_or_raise(fw.executable, fw.path)
    cwd           = File.cwd!
    {:ok, server} = HTTPServer.start_link(ctx, fw_jwt, http_port)

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
      server:   server,
      uuid:     uuid,
      port:     port,
      farmware: fw,
      context:  ctx,
      output:   []
    }

    try do
      %Context{} = ctx = handle_port(state)
      File.cd!(cwd)
      HTTPServer.stop http_port
      ctx
    rescue
      e ->
        File.cd!(cwd)
        reraise(e, System.stacktrace)
    end
  end

  #this is so stupid
  defp lookup_port do
    path = "/tmp/farmware-port"
    last = case File.read(path) do
      {:error, :enoent} -> 8000
      {:ok, str}        -> str |> String.trim() |> String.to_integer()
    end

    if last > 8099 do
      debug_log("using: #{8000}")
      File.write!(path, "#{8000}")
      8000
    else
      debug_log("using: #{last + 1}")
      File.write!(path, "#{last + 1}")
      last + 1
    end

  end

  defp lookup_exec_or_raise(exec, path) do
    real_exe =
      if File.exists?("#{path}/exec") do
        "#{path}/exec"
      else
        System.find_executable(exec)
      end

    if real_exe do
      real_exe
    else
      raise FarmwareRuntimeError,
        message: "Could not locate #{exec}"
    end
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
        debug_log "[#{inspect fw}] sent data: \r\n===========\r\n\r\n#{data} \r\n==========="
        handle_port(state)
      {:EXIT, pid, reason} ->
        debug_log "something died: #{inspect pid} #{inspect reason}"
        maybe_kill_port(port)
        state.context
      after
        @clean_up_timeout ->
          :ok = maybe_kill_port(port)
          raise FarmwareRuntimeError, message: "#{fw.name} time out"
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

  defp environment(%Context{} = ctx, fw_jwt, port) do
    fw_tkn_enc                    = fw_jwt |> Poison.encode! |> :base64.encode()
    envs                          = BotState.get_user_env(ctx)
    {:ok, %Farmbot.Token{} = tkn} = Auth.get_token(ctx.auth)
    envs                          = envs
                                    |> Map.put("API_TOKEN", tkn)
                                    |> Map.put("FARMWARE_TOKEN", fw_tkn_enc)
                                    |> Map.put("FARMWARE_URL", "http://localhost:#{port}/")
                                    |> Map.put("IMAGES_DIR", "/tmp/images")
    Enum.map(envs, fn({key, val}) -> {to_erl_safe(key), to_erl_safe(val)} end)
  end

  defp to_erl_safe(%Farmbot.Token{encoded: enc}), do: to_erl_safe(enc)
  defp to_erl_safe(binary) when is_binary(binary), do: to_charlist(binary)
  defp to_erl_safe(map) when is_map(map), do: map |> Poison.encode! |> to_erl_safe()
  defp to_erl_safe(number) when is_number(number), do: number
end
