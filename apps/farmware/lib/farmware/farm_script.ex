defmodule Farmware.FarmScript do
  @moduledoc """
    A FarmScript is basically a sandboxed shell script.
    This will allow "plugins" to the Farmbot system for people who don't
    speak Elixir.

    * right now we can support `python`, `sh` (no not `bash`), `mruby` (no not ruby) and `elixir`
    * there can only be one script executing at a time (because there is only one gantry)
    * probably only has access to `celery_script` nodes?
    * how to stop `System.cmd`
    * does std::farmbot take priority or scripts?
    * how to get scripts onto the bot?
    * how to handle failures?


  """
  @type t :: %__MODULE__{path: binary}
  @enforce_keys [:path]
  defstruct [:path]

  require Logger

  @doc """
    Executes a farmscript?
    WHATCHU KNOW BOUT ARBITRARY CODE EXECUTION
  """
  @spec run(t) :: pid
  def run(%__MODULE__{} = thing) do
    Logger.debug ">> is running #{inspect thing.path}"
    # Process.flag(:trap_exit, true) # can i put this here?
    port = Port.open({:spawn, thing.path},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout])
    handle_port(port)
  end

  def handle_port(port) do
    receive do
      {^port, {:exit_status, status}} ->
        Logger.debug ">> done! #{inspect status}"
      {^port, {:data, stuff}} ->
        IO.puts stuff
        handle_port(port)
      something ->
        Logger.debug ">> got info: #{inspect something}"
        handle_port(port)
    end
  end
end

# Farmware.Tracker.add %Farmware.FarmScript{path: "echo hello"}
