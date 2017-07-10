defmodule Farmbot.FactoryResetWatcher do
  @moduledoc "Watches a pid and factory resets if it dies."
  use   GenServer
  use   Farmbot.DebugLog
  alias Farmbot.Context

  def start_link(%Context{} = ctx, server, opts \\ []) do
    GenServer.start_link(__MODULE__, {ctx, server}, opts)
  end

  def init({ctx, server}) when is_atom(server) do
    debug_log "Watching #{server}"
    case Process.whereis(server) do
      pid when is_pid(pid) -> init({ctx, pid})
      _ -> {:stop, {:error, :no_proc}}
    end
  end

  def init({_ctx, server}) when is_pid(server) do
    Process.flag(:trap_exit, true)
    {:ok, server}
  end

  def handle_info({:EXIT, _from, reason}, server) when reason in [:normal, :shutdown] do
    {:stop, reason, server}
  end

  def handle_info({:EXIT, from, reason}, server) when from == server do
    msg = """
    Unexpected exit from a watched process.
    #{inspect reason}
    """
    Farmbot.System.factory_reset msg
    {:noreply, server}
  end
end
