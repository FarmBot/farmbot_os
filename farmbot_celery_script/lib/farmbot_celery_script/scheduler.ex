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
  alias FarmbotCeleryScript.Scheduler.CommandRunner
  alias FarmbotCeleryScript.{AST, Compiler}

  defstruct steps: [],
            table: nil,
            execute: nil,
            schedule: nil,
            execute_spec: nil,
            schedule_spec: nil

  @table_name :celery_scheduler

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
  @spec execute(atom, AST.t() | [Compiler.compiled()]) :: {:ok, reference()}
  def execute(table \\ @table_name, celery_script)

  def execute(table, %AST{} = ast) do
    execute(table, Compiler.compile(ast))
  end

  def execute(table, compiled) when is_list(compiled) do
    ref = make_ref()
    :ets.insert(table, {:os.system_time(), {self(), ref}, compiled})
    {:ok, ref}
  end

  @doc """
  Schedule CeleryScript to execute whenever there is time for it.
  Calls are executed in a first in first out buffer, with things being added
  by `execute/2` taking priority.
  """
  @spec schedule(atom, AST.t() | [Compiler.compiled()]) :: {:ok, reference()}
  def schedule(table \\ @table_name, celery_script)

  def schedule(table, %AST{} = ast) do
    schedule(table, Compiler.compile(ast))
  end

  def schedule(table, compiled) when is_list(compiled) do
    # Warning, timestamps may be unstable in offline situations.
    ref = make_ref()
    :ets.insert(table, {nil, {self(), ref}, compiled})
    {:ok, ref}
  end

  @impl true
  def init(args) do
    table = Keyword.get(args, :table, @table_name)
    {:ok, execute} = CommandRunner.start_link(args)
    {:ok, schedule} = CommandRunner.start_link(args)
    send(self(), :checkup)
    execute_spec = nil
    schedule_spec = nil

    {:ok,
     %State{
       table: table,
       execute: execute,
       schedule: schedule,
       execute_spec: execute_spec,
       schedule_spec: schedule_spec
     }}
  end

  @impl true
  def handle_info(:checkup, state) do
    # execute_steps = :ets.select(state.table, fn
    #   {head, from, compiled} when is_number(head) -> {head, from, compiled}
    # end)
    execute_steps =
      :ets.select(state.table, [
        {{:"$1", :"$2", :"$3"}, [is_number: :"$1"], [{{:"$1", :"$2", :"$3"}}]}
      ])

    # schedule_steps = :ets.select(state.table, fn
    #   {head, from, compiled} when is_nil(head) -> {head, from, compiled}
    # end)

    schedule_steps =
      :ets.select(state.table, [
        {{:"$1", :"$2", :"$3"}, [{:==, :"$1", nil}], [{{:"$1", :"$2", :"$3"}}]}
      ])

    # all = :ets.match_object(state.table, {:_, :_, :_})
    # length(all) > 0 && IO.inspect(all, label: "ALL")

    length(execute_steps) > 0 && IO.inspect(execute_steps, label: "EXECUTE")
    length(schedule_steps) > 0 && IO.inspect(schedule_steps, label: "SCHEDULE")
    :ok = GenServer.cast(state.execute, execute_steps)
    :ok = GenServer.cast(state.schedule, schedule_steps)

    for step <- execute_steps ++ schedule_steps do
      true = :ets.delete_object(state.table, step)
    end

    Process.send_after(self(), :checkup, 1000)
    {:noreply, state}
  end
end
