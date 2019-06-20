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
  require Logger
  alias __MODULE__, as: State
  alias FarmbotCeleryScript.{AST, Compiler, StepRunner}

  defstruct next: nil,
            checkup_timer: nil,
            scheduled_pid: nil,
            compiled: [],
            monitors: []

  @doc "Start an instance of a CeleryScript Scheduler"
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @doc """
  Schedule CeleryScript to execute whenever there is time for it.
  Calls are executed in a first in first out buffer, with things being added
  by `execute/2` taking priority.
  """
  @spec schedule(GenServer.server(), AST.t() | [Compiler.compiled()], DateTime.t()) ::
          {:ok, reference()}
  def schedule(scheduler_pid \\ __MODULE__, celery_script, at)

  def schedule(sch, %AST{} = ast, %DateTime{} = at) do
    schedule(sch, Compiler.compile(ast), at)
  end

  def schedule(sch, compiled, at) when is_list(compiled) do
    GenServer.call(sch, {:schedule, compiled, at})
  end

  def get_next(sch \\ __MODULE__) do
    GenServer.call(sch, :get_next)
  end

  @impl true
  def init(_args) do
    send(self(), :checkup)
    {:ok, %State{}}
  end

  @impl true
  def handle_call({:schedule, compiled, at}, {pid, ref} = from, state) do
    state =
      state
      |> monitor(pid)
      |> add(compiled, at, pid)

    :ok = GenServer.reply(from, {:ok, ref})
    schedule_next_checkup(state, 0)
  end

  def handle_call(:get_next, _from, state) do
    {:reply, state.next, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    Logger.debug("Scheduler monitor down: #{inspect(pid)}")

    state =
      state
      |> demonitor({pid, ref})
      |> delete(pid)

    {:noreply, state}
  end

  def handle_info(:checkup, %{next: nil} = state) do
    schedule_next_checkup(state)
  end

  def handle_info(:checkup, %{next: {_compiled, at, _pid}} = state) do
    case DateTime.diff(DateTime.utc_now(), at, :millisecond) do
      # now is before the next date
      diff when diff < 0 ->
        from_now =
          DateTime.utc_now()
          |> DateTime.add(abs(diff), :millisecond)
          |> Timex.from_now()

        Logger.info("Next execution is still #{abs(diff)}ms too early (#{from_now})")
        schedule_next_checkup(state, abs(diff))

      # now is more than 2 minutes (120 seconds) past schedule time
      diff when diff > 120_000 ->
        from_now =
          DateTime.utc_now()
          |> DateTime.add(diff, :millisecond)
          |> Timex.from_now()

        Logger.info("Next execution is #{abs(diff)}ms too late (#{from_now})")
        schedule_next_checkup(state)

      # now is late, but less than 2 minutes late
      diff when diff >= 0 when diff <= 120_000 ->
        Logger.info("Next execution is ready for execution")
        execute_next(state)
    end
  end

  def handle_info({:step_complete, {scheduled_at, executed_at, pid}, result}, state) do
    send(pid, {FarmbtoCeleryScript, {:scheduled_execution, scheduled_at, executed_at, result}})

    state
    |> pop_next()
    |> index_next()
    |> schedule_next_checkup()
  end

  defp execute_next(%{next: {compiled, at, pid}} = state) do
    scheduler_pid = self()

    scheduled_pid =
      spawn(fn -> StepRunner.step(scheduler_pid, {at, DateTime.utc_now(), pid}, compiled) end)

    state = %{state | scheduled_pid: scheduled_pid}
    {:noreply, state}
  end

  defp schedule_next_checkup(state, offset_ms \\ :default)

  defp schedule_next_checkup(%{checkup_timer: timer} = state, offset_ms)
       when is_reference(timer) do
    Process.cancel_timer(timer)
    schedule_next_checkup(%{state | checkup_timer: nil}, offset_ms)
  end

  defp schedule_next_checkup(state, :default) do
    checkup_timer = Process.send_after(self(), :checkup, 15_000)
    state = %{state | checkup_timer: checkup_timer}
    {:noreply, state}
  end

  # If the offset is less than a minute, there will be so little skew that
  # it won't be noticed. This speeds up execution and gets it to pretty
  # close to millisecond accuracy
  defp schedule_next_checkup(state, offset_ms) when offset_ms <= 60000 do
    checkup_timer = Process.send_after(self(), :checkup, offset_ms)
    state = %{state | checkup_timer: checkup_timer}
    {:noreply, state}
  end

  defp schedule_next_checkup(state, _offset_ms) do
    checkup_timer = Process.send_after(self(), :checkup, 15_000)
    state = %{state | checkup_timer: checkup_timer}
    {:noreply, state}
  end

  defp index_next(%{compiled: []} = state), do: %{state | next: nil}

  defp index_next(state) do
    [next | _] =
      compiled =
      Enum.sort(state.compiled, fn
        {_, at, _}, {_, at, _} ->
          true

        {_, left, _}, {_, right, _} ->
          DateTime.compare(left, right) == :lt
      end)

    %{state | next: next, compiled: compiled}
  end

  defp pop_next(%{compiled: [_ | compiled]} = state) do
    %{state | compiled: compiled, scheduled_pid: nil}
  end

  defp pop_next(%{compiled: []} = state) do
    %{state | compiled: [], scheduled_pid: nil}
  end

  defp monitor(state, pid) do
    ref = Process.monitor(pid)
    %{state | monitors: [{pid, ref} | state.monitors]}
  end

  defp demonitor(state, {pid, ref}) do
    monitors =
      Enum.reject(state.monitors, fn
        {^pid, ^ref} -> true
        {_pid, _ref} -> false
      end)

    %{state | monitors: monitors}
  end

  defp add(state, compiled, at, pid) do
    %{state | compiled: [{compiled, at, pid} | state.compiled]}
    |> index_next()
  end

  defp delete(state, pid) do
    compiled =
      Enum.reject(state.compiled, fn
        {_compiled, _at, ^pid} -> true
        {_compiled, _at, _pid} -> false
      end)

    %{state | compiled: compiled}
    |> index_next()
  end
end
