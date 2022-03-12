defmodule FarmbotOS.Celery.Scheduler do
  @moduledoc """
  Handles execution of CeleryScript.

  CeleryScript can be `execute`d or `schedule`d. Both have the same API but
  slightly different behaviour.

  A message will arrive in the callers inbox after either shaped like

      {FarmbotOS.Celery.Scheduler, result}

  where result will be

      :ok | {:error, "some string error"}

  The Scheduler makes no effort to rescue bad syscall implementations. See
  the docs for SysCalls for more details.
  """

  use GenServer
  require Logger
  require FarmbotOS.Logger
  alias FarmbotOS.Celery.{AST, Scheduler, StepRunner}
  alias Scheduler, as: State

  # 15 minutes
  @grace_period_ms 900_000

  defmodule Dispatch do
    defstruct [:scheduled_at, :data]
  end

  defstruct next: nil,
            checkup_timer: nil,
            scheduled_pid: nil,
            ast: [],
            monitors: [],
            registry_name: nil

  @type state :: %State{
          next: nil | {AST.t(), DateTime.t(), data :: map(), pid},
          checkup_timer: nil | reference(),
          scheduled_pid: nil | pid(),
          ast: [{AST.t(), DateTime.t(), data :: map(), pid}],
          monitors: [GenServer.from()],
          registry_name: GenServer.server()
        }

  @doc "Start an instance of a CeleryScript Scheduler"
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  FarmbotOS.Logger.report_termination()

  @doc """
  Schedule CeleryScript to execute whenever there is time for it.
  Calls are executed in a first in first out buffer, with things being added
  by `execute/2` taking priority.
  """
  @spec schedule(
          GenServer.server(),
          AST.t(),
          DateTime.t(),
          map()
        ) ::
          {:ok, reference()}
  def schedule(scheduler_pid \\ __MODULE__, celery_script, at, data)

  def schedule(sch, %AST{} = ast, %DateTime{} = at, %{} = data) do
    GenServer.call(sch, {:schedule, ast, at, data}, 60_000)
  end

  def get_next(sch \\ __MODULE__) do
    GenServer.call(sch, :get_next)
  end

  def get_next_at(sch \\ __MODULE__) do
    case get_next(sch) do
      nil ->
        nil

      {_ast, at, _data, _pid} ->
        at
    end
  end

  @impl true
  def init(args) do
    registry_name = Keyword.get(args, :registry_name, Scheduler.Registry)
    {:ok, _} = Registry.start_link(keys: :duplicate, name: registry_name)
    send(self(), :checkup)
    {:ok, %State{registry_name: registry_name}}
  end

  @impl true
  def handle_call({:schedule, ast, at, data}, {pid, ref} = from, state) do
    state =
      state
      |> monitor(pid)
      |> add(ast, at, data, pid)

    :ok = GenServer.reply(from, {:ok, ref})
    {:noreply, state}
  end

  def handle_call(:get_next, _from, state) do
    {:reply, state.next, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    Logger.info("Scheduler crash: #{inspect pid} #{inspect(reason)}")

    state =
      state
      |> demonitor({pid, ref})
      |> delete(pid)

    {:noreply, state}
  end

  def handle_info(:checkup, %{next: nil} = state) do
    state
    |> schedule_next_checkup()
    |> dispatch()
  end

  def handle_info(:checkup, %{next: {_ast, at, _data, _pid}} = state) do
    case DateTime.diff(DateTime.utc_now(), at, :millisecond) do
      # now is before the next date
      diff_ms when diff_ms < 0 ->
        state
        |> schedule_next_checkup(abs(diff_ms))
        |> dispatch()

      # now is more than the grace period past schedule time
      diff_ms when diff_ms > @grace_period_ms ->
        state
        |> pop_next()
        |> index_next()
        |> schedule_next_checkup()
        |> dispatch()

      # now is late, but less than the grace period late
      diff_ms when diff_ms >= 0 when diff_ms <= @grace_period_ms ->
        Logger.info(
          "Next execution is ready for execution: #{Timex.from_now(at)}"
        )

        state
        |> execute_next()
        |> dispatch()
    end
  end

  def handle_info(
        {:csvm_done, {scheduled_at, executed_at, pid}, result},
        state
      ) do
    send(
      pid,
      {FarmbotOS.Celery,
       {:scheduled_execution, scheduled_at, executed_at, result}}
    )

    state
    |> pop_next()
    |> index_next()
    |> schedule_next_checkup()
    |> dispatch()
  end

  @spec execute_next(state()) :: state()
  defp execute_next(%{next: {ast, at, _data, pid}} = state) do
    scheduler_pid = self()

    scheduled_pid =
      spawn(fn ->
        StepRunner.begin(scheduler_pid, {at, DateTime.utc_now(), pid}, ast)
      end)

    %{state | scheduled_pid: scheduled_pid}
  end

  @spec schedule_next_checkup(state(), :default | integer) :: state()
  defp schedule_next_checkup(state, offset_ms \\ :default)

  defp schedule_next_checkup(%{checkup_timer: timer} = state, offset_ms)
       when is_reference(timer) do
    Process.cancel_timer(timer)
    schedule_next_checkup(%{state | checkup_timer: nil}, offset_ms)
  end

  defp schedule_next_checkup(state, :default) do
    checkup_timer = Process.send_after(self(), :checkup, 15_000)
    %{state | checkup_timer: checkup_timer}
  end

  # If the offset is less than a minute, there will be so little skew that
  # it won't be noticed. This speeds up execution and gets it to pretty
  # close to millisecond accuracy
  defp schedule_next_checkup(state, offset_ms) when offset_ms <= 60000 do
    _ = inspect(offset_ms)
    checkup_timer = Process.send_after(self(), :checkup, offset_ms)
    %{state | checkup_timer: checkup_timer}
  end

  defp schedule_next_checkup(state, offset_ms) do
    _ = inspect(offset_ms)
    checkup_timer = Process.send_after(self(), :checkup, 15_000)
    %{state | checkup_timer: checkup_timer}
  end

  @spec index_next(state()) :: state()
  defp index_next(%{ast: []} = state), do: %{state | next: nil}

  defp index_next(state) do
    [next | _] =
      ast =
      Enum.sort(state.ast, fn
        {_, at, _, _}, {_, at, _, _} ->
          true

        {_, left, _, _}, {_, right, _, _} ->
          DateTime.compare(left, right) == :lt
      end)

    %{state | next: next, ast: ast}
  end

  @spec pop_next(state()) :: state()
  defp pop_next(%{ast: [_ | ast]} = state) do
    %{state | ast: ast, scheduled_pid: nil}
  end

  defp pop_next(%{ast: []} = state) do
    %{state | ast: [], scheduled_pid: nil}
  end

  @spec monitor(state(), pid()) :: state()
  defp monitor(state, pid) do
    already_monitored? =
      Enum.find(state.monitors, fn
        {^pid, _ref} ->
          true

        _ ->
          false
      end)

    if already_monitored? do
      state
    else
      ref = Process.monitor(pid)
      %{state | monitors: [{pid, ref} | state.monitors]}
    end
  end

  @spec demonitor(state(), GenServer.from()) :: state()
  defp demonitor(state, {pid, ref}) do
    monitors =
      Enum.reject(state.monitors, fn
        {^pid, ^ref} ->
          true

        {_pid, _ref} ->
          false
      end)

    %{state | monitors: monitors}
  end

  @spec add(state(), AST.t(), DateTime.t(), data :: map(), pid()) ::
          state()
  defp add(state, ast, at, data, pid) do
    %{state | ast: [{ast, at, data, pid} | state.ast]}
    |> index_next()
  end

  @spec delete(state(), pid()) :: state()
  defp delete(state, pid) do
    ast =
      Enum.reject(state.ast, fn
        {_ast, _at, _data, ^pid} -> true
        {_ast, _at, _data, _pid} -> false
      end)

    %{state | ast: ast}
    |> index_next()
  end

  defp dispatch(%{registry_name: name, ast: ast} = state) do
    calendar =
      Enum.map(ast, fn
        {_ast, scheduled_at, data, _pid} ->
          %Dispatch{data: data, scheduled_at: scheduled_at}
      end)

    Registry.dispatch(name, :dispatch, fn entries ->
      for {pid, _} <- entries do
        do_dispatch(name, pid, calendar)
      end
    end)

    {:noreply, state}
  end

  defp do_dispatch(name, pid, calendar) do
    case Registry.meta(name, {:last_calendar, pid}) do
      {:ok, ^calendar} ->
        Logger.debug("calendar for #{inspect(pid)} hasn't changed")
        {FarmbotOS.Celery, {:calendar, calendar}}

      _old_calendar ->
        Registry.put_meta(name, {:last_calendar, pid}, calendar)
        send(pid, {FarmbotOS.Celery, {:calendar, calendar}})
    end
  end
end
