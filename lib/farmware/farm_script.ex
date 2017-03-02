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

  @typedoc """
    The things required to describe a FarmScript
  """
  @type t ::
    %__MODULE__{executable: binary,
      args: [binary],
      path: binary,
      name: binary,
      envs: [{binary, binary}]}
  @enforce_keys [:executable, :args, :path, :name, :envs]
  defstruct [:executable, :args, :path, :name, :envs]

  require Logger

  @doc """
    Executes a farmscript?
    takes a FarmScript, and some environment vars. [{KEY, VALUE}]
    Exits if anything unexpected happens for saftey.
  """
  @spec run(t, [{charlist, charlist}]) :: pid
  def run(%__MODULE__{} = thing, env) do
    # make sure we have this package installed.
    blah = System.find_executable(thing.executable)
    unless blah, do: raise "Could not find: #{thing.executable}!"

    Logger.info ">> is setting environment for #{thing.name}"

    # why is there two ways to pass envs to farmware?
    extra_env = build_extra_env(thing.envs)

    # get a token. this will raise if there is no token.
    api_env = get_token()

    cwd = File.cwd!
    File.cd!(thing.path)
    port =
      Port.open({:spawn_executable, blah},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout,
       args: thing.args,
       env: env ++ extra_env ++ [api_env]])
    # Handles the life of a farmware.
    handle_port(port, thing)
    # change back to where we started.
    File.cd!(cwd)
  end

  # Credo made me do it
  @spec build_extra_env(list) :: [{charlist,charlist}]
  defp build_extra_env(envs) do
    Enum.map(envs, fn({k, v}) ->
    if is_bitstring(k),
      do: {String.to_charlist(k), String.to_charlist(v)}, else: {k, v}
    end)
  end

  # this will raise if there is no token. This is unintended security lol.
  @spec get_token :: {charlist, charlist}
  defp get_token do
    {:ok, token} = Farmbot.Auth.get_token
    {'API_TOKEN', String.to_charlist(token.encoded)}
  end

  defp handle_port(port, %__MODULE__{} = thing) do
    receive do
      {^port, {:exit_status, 0}} ->
        Logger.info ">> [#{thing.name}] completed!"
      {^port, {:exit_status, s}} ->
        Logger.error ">> [#{thing.name}] completed with errors! (#{s})"

      {^port, {:data, stuff}} ->
        spawn fn() -> handle_script_output(stuff, thing) end
        handle_port(port, thing)

      _something -> handle_port(port, thing)

      after
        10_000 ->
          Logger.error ">> [#{thing.name}] Timed out"
          kill_port(port)
    end
  end

  @spec kill_port(port) :: no_return
  defp kill_port(port) do
    info = Port.info(port)
    if info, do: System.cmd("kill", ["#{info[:os_pid]}"])
  end

  # pattern matching is cool
  defp handle_script_output(string, thing) do
    l = String.split(string, "\n")
    do_sort(l, "", thing)
  end

  defp do_sort(list, acc, thing)
  defp do_sort(["<<< " <> json | tail ], acc, thing) do
    case Poison.decode(json) do
      {:ok, thing} ->
        ast_node = Farmbot.CeleryScript.Ast.parse(thing)
        Farmbot.CeleryScript.Command.do_command(ast_node)
      _ -> Logger.error ">> Got invalid Celery Script from: #{thing.name}"
    end
    do_sort(tail, acc, thing)
  end

  # SHHHHH
  defp do_sort(["EVAL " <> some_code | tail ], acc, thing) do
    Code.eval_string(some_code)
    do_sort(tail, acc, thing)
  end

  defp do_sort([string | tail], acc, thing) do
    do_sort(tail, acc <> "\n" <> string, thing)
  end

  defp do_sort([], acc, thing) do
    Logger.info ">> [#{thing.name}] "<> String.trim(acc)
  end
end
