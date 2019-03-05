defmodule FarmbotCeleryScript.Scheduler do
  @moduledoc """
  Handles execution of CeleryScript.

  CeleryScript can be `execute`d or `schedule`d. Both have the same API but
  slightly different behaviour.

  A message will arrive in the callers inbox after either shaped like

      {FarmbotCeleryScript.Scheduler, result}

  where result will be

      :ok | {:error, "some string error"}

  The Scheduler makes no effort to rescue bad syscall implementations. See
  the docs foro SysCalls for more details.
  """

  use GenServer
  alias __MODULE__, as: State
  alias FarmbotCeleryScript.{AST, RuntimeError, Compiler}

  defstruct steps: [],
            execute: false

  @doc "Start an instance of a CeleryScript Scheduler"
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @doc """
  Execute CeleryScript right now. Multiple calls will always
  execute in the order they were called. This means that if two
  processes call `execute/2` at the exact same time, there could be a
  race condition. In practice this will not happen, because calls are
  executed with a microsecond granularity.

  CeleryScript added via this call will also execute asyncronously to
  that loaded by `schedule/2`. This means for example if there is a `schedule`d
  node currently executing `move_absolute`, and one chooses to `execute`
  `move_absolute` at the same time, the `execute`d call will have somewhat
  undefined behaviour depending on the `move_absolute` implementation.
  """
  @spec execute(GenServer.server(), AST.t() | [Compiler.compiled()]) :: {:ok, reference()}
  def execute(scheduler_pid \\ __MODULE__, celery_script)

  def execute(sch, %AST{} = ast) do
    execute(sch, Compiler.compile(ast))
  end

  def execute(sch, compiled) when is_list(compiled) do
    GenServer.call(sch, {:execute, compiled})
  end

  @doc """
  Schedule CeleryScript to execute whenever there is time for it.
  Calls are executed in a first in first out buffer, with things being added
  by `execute/2` taking priority.
  """
  @spec schedule(GenServer.server(), AST.t() | [Compiler.compiled()]) :: {:ok, reference()}
  def schedule(scheduler_pid \\ __MODULE__, celery_script)

  def schedule(sch, %AST{} = ast) do
    schedule(sch, Compiler.compile(ast))
  end

  def schedule(sch, compiled) when is_list(compiled) do
    GenServer.call(sch, {:schedule, compiled})
  end

  @impl true
  def init(args) do
    {:ok, %State{}}
  end

  @impl true
  def handle_call({:execute, compiled}, {_pid, ref} = from, state) do
    # Warning, timestamps may be unstable in offline situations.
    # IO.inspect(ref, label: "execeuting")
    send(self(), :timeout)
    {:reply, {:ok, ref}, %{state | steps: [{from, :os.system_time(), compiled} | state.steps]}}
  end

  def handle_call({:schedule, compiled}, {_pid, ref} = from, state) do
    # IO.inspect(ref, label: "Scheduling")
    send(self(), :timeout)
    {:reply, {:ok, ref}, %{state | steps: state.steps ++ [{from, nil, compiled}]}}
  end

  @impl true
  def handle_info(:timeout, %{steps: steps} = state) when length(steps) >= 1 do
    [{{_pid, ref} = from, timestamp, compiled} | rest] =
      Enum.sort(steps, fn
        {_, first_ts, _}, {_, second_ts, _} when first_ts <= second_ts -> true
        {_, _, _}, {_, _, _} -> false
      end)

    # IO.inspect(state, label: "timeout")
    case state.execute do
      true ->
        # IO.inspect(ref, label: "already executing")
        {:noreply, state}

      false ->
        # IO.inspect(ref, label: "starting executing")

        {:noreply, %{state | execute: is_number(timestamp), steps: rest},
         {:continue, {from, compiled}}}
    end
  end

  def handle_info(:timeout, %{steps: []} = state) do
    # IO.inspect(state, label: "timeout no steps")
    {:noreply, state}
  end

  @impl true
  def handle_continue({{pid, ref} = from, [step | rest]}, state) do
    case step(state, step) do
      [fun | _] = more when is_function(fun, 0) ->
        {:noreply, state, {:continue, {from, more ++ rest}}}

      {:error, reason} ->
        send(pid, {__MODULE__, ref, {:error, reason}})
        send(self(), :timeout)
        {:noreply, state}

      _ ->
        {:noreply, state, {:continue, {from, rest}}}
    end
  end

  def handle_continue({{pid, ref}, []}, state) do
    send(pid, {__MODULE__, ref, :ok})
    send(self(), :timeout)
    # IO.inspect(ref, label: "complete")
    {:noreply, %{state | execute: false}}
  end

  def step(_state, fun) when is_function(fun, 0) do
    try do
      fun.()
    rescue
      e in RuntimeError -> {:error, Exception.message(e)}
      exception -> reraise(exception, __STACKTRACE__)
    end
  end
end
