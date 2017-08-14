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

  def init({%{body: []}, context, caller}) do
    send caller, {self(), context}
    :ignore
  end

  def init({ast, first_context, caller}) do
    debug_log "[#{inspect self()}] Sequence init."
    # Setup the firt step
    [first | rest] = ast.body
    pid = spawn __MODULE__, :work, [{first, first_context}, self()]
    timer = Process.send_after(:timeout, self(), @step_timeout)
    state = %{
      body: rest,
      context: first_context,
      caller: caller,
      worker: pid,
      timer: timer
    }
    {:ok, state}
  end

  def handle_cast({:error, ex}, state) do
    Process.cancel_timer(state.timer)
    send(state.caller, {self(), {:error, ex}})
    {:stop, :normal, state}
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
    new_state = %{state | body: rest,
      context: next_context,
      worker: pid,
      timer: timer
    }
    {:noreply, new_state}
  end

  def handle_info(:timeout, state), do: {:stop, :timeout, %{state | timer: nil}}

  @spec work({Ast.t, Context.t}, sequence_pid) :: :ok
  def work({ast, context}, sequence) do
    debug_log "[#{inspect self()}] doing work: #{inspect ast}"
    Process.sleep(1000)
    # this might raise.
    
    try do
      new_context = do_command(ast, context)
      GenServer.cast(sequence, {:finished, new_context})
    rescue
      e -> GenServer.cast(sequence, {:error, e})
    end
  end
end
