defmodule Farmbot.Sequence.Manager do
  @moduledoc "Manages a sequence tree"
  alias Farmbot.{Context, DebugLog, CeleryScript, Sequence}
  alias Sequence.Runner
  alias CeleryScript.Ast
  use   GenServer
  use   DebugLog, name: SequenceManager

  @doc """
    Starts managing a sequence. If you want to wait on a sequence, you should do
    a recieve loop and wait for info there.
  """
  def start_link(%Context{} = ctx, %Ast{} = sequence, caller, opts \\ []) do
    GenServer.start_link(__MODULE__, {ctx, sequence, caller}, opts)
  end

  def init({ctx, sequence_ast, caller}) do
    case Runner.start_link(ctx, sequence_ast, self()) do
      {:ok, sequence_pid} ->
        Process.flag(:trap_exit, true)
        Process.link(sequence_pid)
        {:ok, %{context: ctx, caller: caller, sequence_pid: sequence_pid}}
      :ignore ->
        send(caller, {self(), ctx})
        :ignore
      err -> {:stop, err}
    end
  end

  def handle_info({_pid, %Context{} = ctx}, %{sequence_pid: _sequence_pid} = state)  do
    {:noreply, %{state | context: ctx}}
  end

  def handle_info({:EXIT, _pid, :normal}, %{sequence_pid: _sequence_pid} = state) do
    debug_log "Sequence completed successfully."
    send state.caller, {self(), state.context}
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, reason}, %{sequence_pid: _sequence_pid} = state) do
    debug_log "Caught sequence exit error: #{inspect reason}"
    send state.caller, {self(), {:error, reason}}
    {:stop, reason, state}
  end

end
