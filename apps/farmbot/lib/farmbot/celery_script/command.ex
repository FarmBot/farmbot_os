defmodule Farmbot.CeleryScript.Command do
  @moduledoc """
    Actionable CeleryScript Commands.
    There should be very little side affects here. just serial commands and
    ways to execute those serial commands.
    this means minimal logging, minimal bot state changeing (if its not the
    result of a gcode) etc.
  """
  require Logger
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Sequencer
  alias Farmbot.Serial.Gcode.Handler, as: GcodeHandler
  alias Farmbot.Serial.Gcode.Parser, as: GcodeParser
  alias Farmbot.BotState
  use Amnesia
  alias Amnesia.Selection
  alias Farmbot.Sync
  alias Farmbot.Sync.Databse
  alias Sync.Database.Tool
  alias Sync.Database.Sequence
  alias Sync.Database.ToolSlot
  use Tool
  use ToolSlot
  use Sequence

  use Farmbot.CeleryScript.Command.Builder


  @type nobod :: []
  @nobod []
  @type noargs :: %{}
  @noargs %{}

  # TODO: Move everythign below this into this format.
  import_all_commands

  @spec get_slot_from_tool(Tool.t) :: coordinate
  defp get_slot_from_tool(%Tool{} = t) do
    Amnesia.transaction do
      sel = ToolSlot.where tool_id == t.id
      [slot] = Selection.values(sel)
      coordinate(%{x: slot.x, y: slot.y, z: slot.z}, [])
    end
  end

  @doc """
    Moves relative from wherever the bot currently is.
      args: %{x: integer, y: integer, z: integer, speed: integer}
      body: #{@nobod}
  """
  @spec move_relative(%{x: integer, y: integer, z: integer, speed: integer},
    nobod) :: no_return
  def move_relative(%{x: x, y: y, z: z, speed: s}, @nobod) do
    move_absolute(
    %{location: current_position_to_coord,
      offset:   coordinate(%{x: x, y: y, z: z}, @nobod),
      speed: s}, @nobod)
  end

  # helper to turn the bots state to a coordinate ast node
  @spec current_position_to_coord :: coordinate
  defp current_position_to_coord do
    [cx, cy, cz] = BotState.get_current_pos
    coordinate(%{x: cx, y: cy, z: cz}, @nobod)
  end

  @doc """
    The nothing ast node.
      args: %{}
      body: %{}
  """
  @type nothing :: nil
  @spec nothing(any, any) :: nothing
  def nothing(_, _), do: nil

  @doc """
    Returns a coridinate.
      args: %{x: integer, y: integer, z: integer}
      body: []
  """
  @type coordinate_args :: %{x: integer, y: integer, z: integer}
  @type coordinate :: %Ast{kind: String.t, args: coordinate_args, body: []}
  @spec coordinate(coordinate_args, []) :: coordinate
  def coordinate(%{x: _x, y: _y, z: _z} = args, [] = body) do
    %Ast{kind: "coordinate", args: args, body: body}
  end

  @doc """
    Gets a tool from the database
      args: %{tool_id: integer},
      body: #{@nobod}
  """
  @type tool :: %Ast{kind: String.t, args: %{tool_id: integer}, body: []}
  @spec tool(%{tool_id: integer}, []) :: Tool.t | nil
  def tool(%{tool_id: id}, []) do
    Sync.get_tool(id)
  end

  @doc """
    Write a pin.
      args: %{pin_number: integer, pin_value: integer, pin_mode: 0 | 1}
      body: #{@nobod}
  """
  @spec write_pin(%{pin_number: integer, pin_value: integer, pin_mode: 0 | 1},
    nobod) :: no_return
  def write_pin(%{pin_number: pin, pin_value: value, pin_mode: mode}, @nobod) do
    BotState.set_pin_mode(pin, mode)
    BotState.set_pin_value(pin, value)
    GcodeHandler.block_send("F41 P#{pin} V#{value} M#{mode}")
  end

  @doc """
    Read a pin.
      args: %{pin_number: integer, data_label: String.t, pin_mode: 0 | 1}
      body: #{@nobod}
  """
  @spec read_pin(%{pin_number: integer, data_label: integer, pin_mode: 0 | 1},
    nobod) :: no_return
  def read_pin(%{pin_number: pin, data_label: _, pin_mode: mode}, @nobod) do
    BotState.set_pin_mode(pin, mode)
    GcodeHandler.block_send("F42 P#{pin} M#{mode}")
  end

  @doc """
    Returns a channel AST.
      args: %{channel_name: String.t}
      body: #{@nobod}
  """
  @type channel :: %Ast{kind: String.t, args: channel_args, body: nobod}
  @type channel_args :: %{channel_name: String.t} # "toast" | "sms" | "email"
  @spec channel(channel_args, nobod) :: channel
  def channel(%{channel_name: _name} = channel_args, @nobod) do
    %Ast{kind: "channel", args: channel_args, body: @nobod}
  end

  @doc """
    Waits for a specified amount of milliseconds
      args: %{milliseconds: integer},
      body: #{@nobod}
  """
  @spec wait(%{milliseconds: integer}, nobod) :: no_return
  def wait(%{milliseconds: millis}, @nobod) do
    Process.sleep(millis)
  end

  @doc """
    Logs a message to a channel (and the logger)
      args: %{message: String.t, message_type: String.t},
      body: [channel]
  """
  @spec send_message(%{message: String.t, message_type: String.t},
  [channel]) :: no_return
  def send_message(%{message: m, message_type: mt}, channels) do
    ch = Enum.map(channels, fn(chan) ->
      chan.args.channel_name
    end)
    rendered = Mustache.render(m, get_templates)
    Logger.debug ">> #{rendered}", channels: ch, type: mt
  end

  # this is pretty basic right now but will change later
  defp get_templates do
    [x, y, z] = BotState.get_current_pos
    %{x: x, y: y, z: z}
  end

  @doc """
    Does a sequence
      args: %{version: integer}
      body: [Ast.t]
  """
  @spec sequence(%{version: integer}, [Ast.t]) :: {:ok, pid}
  def sequence(args, nodes) do
    Sequencer.start_link(%Ast{kind: "sequence", args: args, body: nodes})
  end

  @doc """
    Executes a sequence
      args: %{sub_sequence_id: integer}
      body: #{@nobod}
  """
  @type execute ::
    %Ast{kind: String.t, args: %{sub_sequence_id: integer}, body: nobod}
  @spec execute(%{sub_sequence_id: integer}, nobod) :: no_return
  def execute(%{sub_sequence_id: id}, @nobod) do
    case Sync.get_sequence(id) do
      nil ->
        Logger.error ">> could not find sequence!"
      %Sequence{} = seq ->
        seq |> Ast.parse |> mutate_sequence(seq.name) |> do_command
    end
  end

  @doc """
    Copys sequence name into its args.
  """
  @spec mutate_sequence(Ast.t, String.t) :: Ast.t
  def mutate_sequence(%Ast{} = seq, name) do
    %Ast{seq | args: Map.put(seq.args, :name, name)}
  end

  @doc """
    This is soon to be depreciated.
      args: %{lhs: String.t
              rhs: integer,
              op: String.t
              sub_sequence_id: integer}
      body: #{@nobod}
  """
  @spec if_statement(map, nobod) :: no_return
  def if_statement(%{lhs: lhs, rhs: rhs, op: op, sub_sequence_id: ssid}, []) do
    l = lhs |> parse_lhs
    if do_if(l, op, rhs) do
      execute(%{sub_sequence_id: ssid}, [])
    end
  end

  @doc """
    Conditionally runs an execute node.
      args: %{lhs: String.t,
              rhs: integer,
              op: String.t,
              _else: execute | _if | nothing,
              _then: execute | nothing }
      body: #{@nobod}
  """
  @type _if :: %Ast{kind: String.t, args: _if_args, body: nobod}
  @type _if_args ::
        %{lhs: String.t,
          rhs: integer,
          op: String.t,
          _else: execute | _if | nothing,
          _then: execute | nothing}
  @spec _if(_if_args, nobod) :: no_return
  def _if(%{lhs: lhs, rhs: rhs, op: op, _else: else_, _then: then_}, @nobod) do
    l = lhs |> parse_lhs
    if do_if(l, op, rhs) do
      do_command(then_)
    else
      do_command(else_)
    end
  end

  defp do_if(nil, _, _) do
    Logger.error ">> Could not complete if statement"
    false
  end

  defp do_if(lhs, ">", rhs) when is_integer(lhs) and is_integer(rhs) do
    lhs > rhs
  end

  defp do_if(lhs, "<", rhs) when is_integer(lhs) and is_integer(rhs) do
    lhs < rhs
  end

  defp do_if(lhs, "is", rhs) when is_integer(lhs) and is_integer(rhs) do
    lhs == rhs
  end

  defp do_if(lhs, "not", rhs) when is_integer(lhs) and is_integer(rhs) do
    lhs != rhs
  end

  @spec parse_lhs(String.t) :: integer | nil
  defp parse_lhs("pin" <> num) do
    pin = String.to_integer(num)
    case BotState.get_pin(pin) do
      nil -> nil
      %{mode: _, value: value} -> value
    end
  end

  defp parse_lhs("x"), do: position(:x)
  defp parse_lhs("y"), do: position(:y)
  defp parse_lhs("z"), do: position(:z)

  defp parse_lhs(thing) do
    Logger.debug "unrecognized left hand side for if: #{inspect thing}"
    nil
  end

  @spec position(:x | :y | :z) :: integer | nil
  defp position(axis) do
    [x, y, z] = BotState.get_current_pos
    Keyword.get([x: x, y: y, z: z], axis)
  end

  @doc """
    Executes an ast node.
  """
  @spec do_command(Ast.t) :: :no_instruction | any
  def do_command(%Ast{} = ast) do
    # i wish there was a better way to do this?
    fun_name = String.to_atom(ast.kind)
    if function_exported?(__MODULE__, fun_name, 2) do
      Kernel.apply(__MODULE__, fun_name, [ast.args, ast.body])
    else
      Logger.error ">> has no instruction for #{ast.kind}"
      :no_instruction
    end
  end


end
