defmodule Farmbot.Scheduler.Sequence.InstructionSet_0 do
  # dont lint the module name because its kind of special.
  @lint {Credo.Check.Readability.ModuleNames, false}
  @moduledoc """
    Modules under this namespace will be similar to how the API's database
    migrations work. If ever there is a breaking change, in the frontend
    the sequencer can still use the old set of instructions
  """
  use GenServer
  require Logger

  def start_link(parent) do
    Logger.debug ">> is initializing sequence instruction set 0"
    GenServer.start_link(__MODULE__, parent)
  end

  def init(parent), do: {:ok, parent}

  # I wanted this to be a little more dry, so here we go.
  def handle_cast(maybe_ast_node, parent),
    do: maybe_ast_node |> Ast.parse |> do_step(parent)

  @doc """
    actually does the step
  """
  @spec do_step(Ast.t | any, pid) :: {:noreply, pid}

  def do_step(%Ast{kind: "send_message",
                   body: body,
                   args: %{message: message}},
  parent) do
    sequence_name = GenServer.call(parent, :name)
    vars = GenServer.call(parent, :get_all_vars, :infinity)
    rendered = Mustache.render(message, vars)
    # TODO THIS WILL CHANGE
    Logger.debug(rendered)
    dispatch :done, parent
  end

  def do_step(%Ast{kind: "wait",
                   body: [],
                   args: %{milliseconds: millis}},
  parent) do
    # Doing a user defined sleep in a GenServer callback. YOLO
    Process.sleep(millis)
    dispatch :done, parent
  end

  def do_step(%Ast{kind: "if_statement",
                   body: [],
                   args: %{lhs: lhs, rhs: rhs, op: op, sub_sequence_id: id}},
  parent) do
    if do_if(parse_if(lhs, parent), op, parse_if(rhs, parent)) == true do
      do_step(%Ast{kind: "execute", body: [], args: %{sub_sequence_id: id}}, parent)
    else
      dispatch :done, parent
    end
  end

  def do_step(%Ast{kind: "execute",
                   body: [],
                   args: %{sub_sequence_id: id}},
  parent) do
    GenServer.call(Farmbot.Scheduler.Sequence.Manager, {:pause, parent})
    sequence = Farmbot.Sync.get_sequence(id)
    GenServer.call(Farmbot.Scheduler.Sequence.Manager, {:add, sequence})
    no_dispatch parent
  end

  #############################################################################
  ##                            BOT COMMANDS                                 ##
  #############################################################################

  @lint false # don't lint because piping x into move_absolute would look funny.
  # MOVE ABSOLUTE
  def do_step(%Ast{kind: "move_absolute",
                   args: %{speed: s, x: x, y: y, z: z},
                   body: []}, parent)
  do
    Command.move_absolute(x,y,z,s) |> dispatch(parent)
  end

  # MOVE RELATIVE
  @lint false # don't lint because piping x into move_rel would look funny.
  def do_step(%Ast{kind: "move_relative",
                   args: %{speed: s, x: x, y: y, z: z},
                   body: []}, parent)
  do
    Command.move_relative(%{speed: s, x: x, y: y, z: z}) |> dispatch(parent)
  end

  # WRITE PIN
  def do_step(%Ast{kind: "write_pin",
                   args: %{pin_mode: mode, pin_number: num, pin_value: val},
                   body: []}, parent)
  do
    num |> Command.write_pin(val, mode) |> dispatch(parent)
  end

  # READ PIN
  def do_step(%Ast{kind: "read_pin",
                   args: %{data_label: label, pin_mode: mode, pin_number: num},
                   body: []}, parent)
  do
    output = Command.read_pin(num, mode)
    %{mode: ^mode, value: val} = Farmbot.BotState.get_pin(num)
    GenServer.call(parent, {:set_var, label, val})
    dispatch output, parent
  end

  def do_step(%Ast{kind: "DELETE_ME",
                   args: %{},
                   body: []}, parent)
  do
    dispatch {:delete_me}, parent
  end

  # Catch all
  def do_step(thing, parent) do
    Logger.error ">> couldnt handle #{inspect thing}!"
    dispatch {:unhandled, thing}, parent
  end

  @spec channels([Ast.t,...]) :: [atom,...]
  defp channels(list) when list |> is_list do
    Enum.reduce(list, [],
      fn(%Ast{kind: "channel",
              args: %{channel_name: c},
              body: []},acc) -> [c | acc] end)
  end

  @spec parse_if(any, pid) :: integer | nil
  defp parse_if(number, _) when is_integer(number), do: number
  defp parse_if(something, parent) do
    vars = GenServer.call(parent, :get_all_vars)
    Map.get(vars, String.to_atom(something))
  end

  # This happens if the thing the user is looking for isnt in the bot state.
  # I think the bottom function actually cathes this...
  @spec do_if(nil, String.t, nil) :: false
  defp do_if(l,">",r) when is_nil(l) or is_nil(r), do: false

  # If the parsing worked properly we should have two integers
  @spec do_if(integer, String.t, integer) :: true | any
  defp do_if(l,">",r) when l > r, do: true
  defp do_if(l,"<",r) when l < r, do: true
  defp do_if(l,"is",r) when l == r, do: true
  defp do_if(l,"not",r) when l != r, do: true
  defp do_if(l, _, r) when is_integer(l) and is_integer(r), do: false
  defp do_if(l, op, r), do: Logger.debug ">> couldn't parse if:[#{l} #{op} #{r}]"

  @spec dispatch(atom, pid) :: {:noreply, pid}
  defp dispatch(status, parent), do: Farmbot.Scheduler.Sequence.VM.tick(parent, status)
  @spec no_dispatch(pid) :: {:noreply, pid}
  defp no_dispatch(parent), do: {:noreply, parent}
end
