defmodule Farmbot.Sequence.Runner do
  @moduledoc """
    Runs a sequence
  """
  use     GenServer
  alias   Farmbot.{CeleryScript, Context, DebugLog}
  alias   CeleryScript.Ast
  import  CeleryScript.Command, only: [do_command: 2]
  require Logger
  use     DebugLog

  @typedoc """
    This gets injected into the args of a sequence, and all of its children etc.
    Mostly magic.
  """
  @type context :: Context.t
  @type sequence_pid :: pid

  @type block :: {reference, pid}

  @type state :: %{
    blocks: [block],
    body: [Ast.t]
  }

  @step_timeout 15_000

  @doc """
    Starts a sequence.
  """
  def start_link(%Context{} = ctx, %Ast{} = ast, caller) do
    GenServer.start_link(__MODULE__, {ast, ctx, caller}, [])
  end

  def init({ast, first_context, caller}) do
    Process.flag(:trap_exit, true)
    debug_log "[#{inspect self()}] Sequence init."
    # Setup the firt step
    [first | rest] = ast.body
    pid = spawn __MODULE__, :work, [{first, first_context}, self()]
    Process.link(pid)
    timer = Process.send_after(:timeout, self(), @step_timeout)
    {:ok, %{body: rest, context: first_context, caller: caller, worker: pid, timer: timer}}
  end

  # When a stop finishes and there is no more steps
  def handle_cast({:finished, next_context}, %{body: []} = state) do
    Process.cancel_timer(state.timer)
    send(state.caller, {self(), next_context})
    {:stop, :normal, %{state | context: next_context, timer: nil}}
  end

  def handle_cast({:finished, next_context}, %{body: rest} = state) do
    Process.cancel_timer(state.timer)
    send(state.caller, {self(), next_context})
    [first | rest] = rest
    pid = spawn __MODULE__, :work, [{first, next_context}, self()]
    Process.link(pid)
    timer = Process.send_after(:timeout, self(), @step_timeout)
    {:noreply, %{state | body: rest, context: next_context, worker: pid, timer: timer}}
  end

  def handle_info({:EXIT, _, :normal}, state), do: {:noreply, state}

  def handle_info({:EXIT, pid, reason}, %{worker: worker} = state) when pid == worker do
    debug_log "Sequence terminating."
    {:stop, reason, state}
  end

  def handle_info(:timeout, state), do: {:stop, :timeout, %{state | timer: nil}}

  @spec work({Ast.t, Context.t}, sequence_pid) :: :ok
  def work({ast, context}, sequence) do
    debug_log "[#{inspect self()}] doing work: #{inspect ast}"
    # This sleep makes sequences more stable and makes sure
    # The bot was _actualy_ complete with the last command in real life.
    Process.sleep(500)
    # this might raise.
    new_context = do_command(ast, context)
    GenServer.cast(sequence, {:finished, new_context})
  end
end
