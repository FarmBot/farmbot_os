defmodule Farmbot.Serial.Handler.OpenTTY do
  @moduledoc false
  alias Nerves.UART
  alias Farmbot.Serial.Handler
  use Farmbot.DebugLog
  import Supervisor.Spec
  alias Farmbot.Context

  @baud 115_200

  defp ensure_supervisor(sup, retries \\ 0)

  defp ensure_supervisor(sup, retries) when retries > 25 do
    :error
  end

  defp ensure_supervisor(sup, retries) when is_atom(sup) do
    case Process.whereis(sup) do
      pid when is_pid(pid) -> ensure_supervisor(pid, retries + 1)
      _ -> ensure_supervisor(sup, retries + 1)
    end
  end

  defp ensure_supervisor(sup, retries) when is_pid(sup) do
    if Process.alive?(sup) do
      debug_log "Serial has a supervisor."
      :ok
    else
      debug_log "Waiting for serial to find a supervisor."
      ensure_supervisor(sup, retries + 1)
    end
  end

  if Mix.Project.config[:target] != "host" do

    # if runnin on the device, enumerate any uart devices and open them
    # individually.
    @spec open_ttys(atom | pid, Context.t, [binary] | nil) :: :ok | no_return
    def open_ttys(supervisor, %Context{} = ctx, ttys \\ nil) do
      ensure_supervisor(supervisor)
      blah = ttys || UART.enumerate() |> Map.drop(["ttyS0","ttyAMA0"]) |> Map.keys
      case blah do
        [one_tty] ->
          debug_log "trying to open: #{one_tty}"
          thing = {one_tty, ctx, [name: Farmbot.Serial.Handler]}
          try_open([thing], supervisor)
        ttys when is_list(ttys) ->
          raise "Too many ttys!"
      end
    end
  else

    # If running in the host environment the proper tty is expected to be in
    # the environment
    defp get_tty do
      case Application.get_env(:farmbot, :tty) do
        {:system, env} -> System.get_env(env)
        tty when is_binary(tty) -> tty
        _ -> nil
      end
    end

    @spec open_ttys(atom | pid, Context.t, [binary] | nil) :: :ok | no_return
    def open_ttys(supervisor, context, list \\ nil)
    def open_ttys(supervisor, %Context{} = ctx, _) do
      ensure_supervisor(supervisor)
      if get_tty() do
        thing = {get_tty(), ctx, [name: Farmbot.Serial.Handler]}
        try_open([thing], supervisor)
      else
        debug_log ">> Please export ARDUINO_TTY in your environment"
        :ok
      end
    end
  end

  @spec try_open([{binary, Context.t, [any]}], atom | pid) :: :ok | no_return
  defp try_open([], _), do: :ok
  defp try_open([{tty, %Context{} = ctx, opts} | rest], sup) do
    {:ok, nerves} = UART.start_link()
    nerves
    |> UART.open(tty, speed: @baud, active: false)
    |> supervise_process({tty, ctx, opts}, sup, nerves)

    try_open(rest, sup)
  end

  @spec supervise_process(any, binary, atom | pid, atom | pid)
    :: {:ok, pid} | false | no_return
  defp supervise_process(:ok, {tty, %Context{} = ctx, opts}, sup, nerves) do
    worker_spec = worker(Handler, [ctx, nerves, tty, opts], [restart: :permanent])
    UART.close(nerves)
    Process.sleep(1500)
    {:ok, _pid} = Supervisor.start_child(sup, worker_spec)
  end

  defp supervise_process(resp, {tty, %Context{}, _opts}, _, nerves) do
    GenServer.stop(nerves, :normal)
    raise "Could not open #{tty}: #{inspect resp}"
    false
  end
end
