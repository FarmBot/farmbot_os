defmodule Farmbot.Serial.Handler.OpenTTY do
  @moduledoc false
  import  Supervisor.Spec
  alias   Farmbot.{Context, Serial}
  alias   Serial.Handler
  use     Farmbot.DebugLog
  import  __MODULE__.EnvTargetDetector

  @doc """
    Opens a serial device and ensures it is supervised.
  """
  def open_ttys(%Context{} = ctx, supervisor) do
    debug_log "Detecting ttys."
    tty = try_detect_tty()
    if tty do
      debug_log "Trying to open tty."
      worker_spec = worker(Handler,
        [ctx, tty, [name: Handler]],
          [restart: :permanent])
      {:ok, _} = Supervisor.start_child(supervisor, worker_spec)
    else
      debug_log "Not opening tty."
      nil
    end
  end

  case {Mix.env(), Mix.Project.config[:target]} do
    {:dev,  "host"}   -> dev_host()
    {:test, "host"}   -> test_host()
    {env_,   target_} -> target(unquote(env_), unquote(target_))
  end
end
