defmodule Farmbot.CeleryScript.Sequencer do
  @moduledoc """
    Executes a script of ast nodes.
  """

  defmodule State do
    @moduledoc """
      State of the Sequencer.
    """
    alias Farmbot.CeleryScript.Ast
    @type t ::
      %__MODULE__{name: String.t,
                  sequence: Ast.t,
                  step: Ast.t,
                  nodes: [Ast.t]}
    @enforce_keys [:name, :sequence, :step, :nodes]
    defstruct @enforce_keys
  end

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  use GenServer

  @doc """
    Starts executing a Sequence.
  """
  @spec start_link(Ast.t) :: {:ok, pid}
  def start_link(%Ast{} = seq) do
    if Map.has_key?(seq.args, :name) do
      Logger.debug ">> [#{seq.args.name}] starting!"
      GenServer.start_link(__MODULE__, {seq, seq.args.name})
    else
      Logger.warn ">> Starting an anonymous sequence!"
      GenServer.start_link(__MODULE__, {seq, "anon"})
    end
  end

  @spec init({Ast.t, String.t}) :: {:ok, State.t}
  @doc false
  def init({seq, name}) do
    initial =
      %State{step: List.first(seq.body),
             sequence: seq,
             name: name,
             nodes: seq.body}
    # i really don't like doing this.
    tick
    {:ok, initial}
  end

  # i really dont like this
  defp tick, do: Process.send_after(self, :tick, 100)

  # when we are on the last step.
  def handle_info(:tick,
    %State{nodes: [_node], step: step, sequence: seq, name: name})
  do
    Logger.debug ">> [#{name}] - [#{step.kind}]"
    Command.do_command(step)
    this = self
    spawn fn() -> GenServer.stop(this, :normal) end
    {:noreply, %State{nodes: [], step: nil, sequence: seq, name: name}}
  end

  def handle_info(:tick, state) do
    Logger.debug ">> [#{state.name}] - [#{state.step.kind}]"
    Command.do_command(state.step)
    [_h | new_nodes] = state.nodes
    tick
    {:noreply, %State{state | nodes: new_nodes, step: List.first(new_nodes)}}
  end

  def terminate(:normal,state) do
    Logger.debug ">> [#{state.name}] is finished."
  end

  def terminate(_, state) do
    Logger.error ">> [#{state.name}] finished erronously."
  end
end
