defmodule Farmware.FarmScript do
  @moduledoc """
    A FarmScript is basically a sandboxed shell script.
    This will allow "plugins" to the Farmbot system for people who don't
    speak Elixir.

    * right now we can support `python`, `sh` (no not `bash`), `mruby` (no not ruby) and `elixir`
    * actually we can't support Elixir lol
    * there can only be one script executing at a time (because there is only one gantry)
    * probably only has access to `celery_script` nodes?
    * how to stop `System.cmd`
    * does std::farmbot take priority or scripts?
    * how to handle failures?
  """

  @type t :: %__MODULE__{executable: binary, args: [binary], path: binary, name: binary}
  @enforce_keys [:executable, :args, :path, :name]
  defstruct [:executable, :args, :path, :name]

  require Logger

  @doc """
    Executes a farmscript?
    takes a FarmScript, and some environment vars. [{KEY, VALUE}]
    Exits if anything unexpected happens for saftey.
  """
  @spec run(t, [{any, any}]) :: pid
  def run(%__MODULE__{} = thing, env) do
    Logger.debug ">> is setting environment for #{thing.name}"

    blah = System.find_executable(thing.executable)
    if !blah do
      raise "#{thing.executable} does not exist!"
    end

    cwd = File.cwd!
    File.cd!(thing.path)
    port =
      Port.open({:spawn_executable, blah},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout, args: thing.args, env: env])
    handle_port(port, thing)
    # change back to where we started.
    File.cd!(cwd)
  end

  defp handle_port(port, %__MODULE__{} = thing) do
    # Inside this probably we need to build some sort of
    # timeout mech and handle zombie processes and what not.
    receive do
      {^port, {:exit_status, 0}} ->
        Logger.debug ">> #{thing.name} completed!"
      {^port, {:exit_status, s}} ->
        Logger.error ">> #{thing.name} completed with errors! (#{s})"
      {^port, {:data, stuff}} ->
        Logger.debug "[#{thing.name}]:<< " <> String.trim(stuff) <> " >>"
        handle_port(port, thing)
      _something ->
        # Logger.debug ">> [#{thing.name}] [ got info: #{inspect something} ]"
        handle_port(port, thing)
    end
  end
end
