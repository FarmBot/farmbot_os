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
  alias Farmbot.Serial.Gcode.Handler, as: GHan
  alias Farmbot.Serial.Gcode.Parser, as: GParser
  alias Amnesia
  use Amnesia
  alias Farmbot.Sync.Database.ToolSlot
  use ToolSlot

  @doc """
    move_absolute to a prticular position.
      args: %{
        speed: integer,
        offset: coordinate_ast | Ast.t
        location: coordinate_ast | Ast.t
      },
      body: []
  """
  @type move_absolute_args :: %{
    speed: integer,
    offset: coordinate_ast | Ast.t,
    location: coordinate_ast | Ast.t
  }
  @spec move_absolute(move_absolute_args, []) :: no_return
  def move_absolute(%{speed: s, offset: offset, location: location}, []) do
    with %Ast{kind: "coordinate", args: %{x: xa, y: ya, z: za}, body: []} <-
            ast_to_coord(location),
         %Ast{kind: "coordinate", args: %{x: xb, y: yb, z: zb}, body: []} <-
            ast_to_coord(offset)
    do
      "G00 X#{xa + xb} Y#{ya + yb} Z#{za + zb} S#{s}" |> GHan.block_send
    else
      _ -> Logger.error ">> error doing Move absolute!"
    end
  end

  @doc """
    move_relative to a location
      args: %{speed: number, x: number, y: number, z: number}
      body: []
  """
  @spec move_relative(%{speed: number, x: x, y: y, z: z}, [])
    :: no_return
  def move_relative(%{speed: speed, x: x, y: y, z: z}, []) do
    # make a coordinate of the relative movement we want to do
    location = coordinate(%{x: x, y: y, z: z}, [])

    # get the current position, then turn it into another coord.
    [cur_x,cur_y,cur_z] = Farmbot.BotState.get_current_pos
    offset = coordinate(%{x: cur_x, y: cur_y, z: cur_z}, [])
    move_absolute(%{speed: speed, offset: offset, location: location}, [])
  end

  @doc """
    Convert an ast node to a coodinate or return :error.
  """
  @spec ast_to_coord(Ast.t) :: coordinate_ast | :error
  def ast_to_coord(ast)
  def ast_to_coord(%Ast{kind: "coordinate",
                        args: %{x: _x, y: _y, z: _z},
                        body: []} = already_done), do: already_done

  def ast_to_coord(%Ast{kind: "tool", args: %{tool_id: id}, body: []}) do
    blah =
      Amnesia.transaction do
        [asdf] =
          ToolSlot.where(tool_id == id)
          |> Amnesia.Selection.values
          asdf
      end

    if blah do
      coordinate(%{x: blah.x, y: blah.y, z: blah.z}, [])
    else
      Logger.error ">> could not find tool_slot with tool_id: #{id}"
      :error
    end
  end

  def ast_to_coord(ast) do
    Logger.warn ">> no conversion from #{inspect ast} to coordinate"
    :error
  end

  @doc """
    coodinate
      args: %{x: integer, y: integer, z: integer}
      body: []
  """
  @type x :: integer
  @type y :: integer
  @type z :: integer
  @type coord_args :: %{x: x, y: y, z: z}
  @type coordinate_ast :: %Ast{kind: String.t, args: coord_args, body: []}
  @spec coordinate(coord_args, []) :: coordinate_ast
  def coordinate(%{x: _x, y: _y, z: _z} = args, []) do
    %Ast{kind: "coordinate", args: args, body: []}
  end

  @doc """
    read_status
      args: %{},
      body: []
  """
  @spec read_status(%{}, []) :: no_return
  def read_status(%{}, []), do: Farmbot.BotState.Monitor.get_state

  @doc """
    sync
      args: %{},
      body: []
  """
  @spec sync(%{}, []) :: no_return
  def sync(%{}, []), do: Farmbot.Sync.sync

  @doc """
    Handles an RPC Request.
      args: %{data_label: String.t},
      body: [Ast.t,...]
  """
  @spec rpc_request(%{data_label: String.t}, [Ast.t, ...]) :: no_return
  def rpc_request(%{data_label: id}, more_stuff) do
    more_stuff
    |> Enum.reduce({[],[]}, fn(ast, {win, fail}) ->
      fun_name = String.to_atom(ast.kind)
      if function_exported?(__MODULE__, fun_name, 2) do
        # actually do the stuff here?
        spawn fn() ->
          do_command(ast)
        end
        {[ast | win], fail}
      else
        i_suck = explanation(%{message: "unhandled: #{fun_name}"}, [])
        Logger.error ">> got an unhandled rpc request: #{fun_name} #{inspect ast}"
        {win, [i_suck | fail]}
      end
    end)
    |> handle_req(id)
  end

  @spec handle_req({Ast.t, [explanation_type]}, String.t) :: no_return
  defp handle_req({_, []}, id) do
    # there were no failed asts.
    rpc_ok(%{data_label: id}, []) |> Farmbot.Transport.emit
  end

  defp handle_req({_, failed}, id) do
    # there were some failed asts.
    rpc_error(%{data_label: id}, failed) |> Farmbot.Transport.emit
  end

  @doc """
    Return for a valid Rpc Request
      args: %{data_label: String.t},
      body: []
  """
  @spec rpc_ok(%{data_label: String.t}, []) :: Ast.t
  def rpc_ok(%{data_label: id}, []) do
    %Ast{kind: "rpc_ok", args: %{data_label: id}, body: []}
  end

  @doc """
    bad return for a valid Rpc Request
      args: %{data_label: String.t},
      body: [Explanation]
  """
  @spec rpc_error(%{data_label: String.t}, [explanation_type]) :: Ast.t
  def rpc_error(%{data_label: id}, explanations) do
    %Ast{kind: "rpc_error", args: %{data_label: id}, body: explanations}
  end

  @doc """
    Explanation for an rpc error
      args: %{data_label: String.t},
      body: []
  """
  @type explanation_type ::
    %Ast{kind: String.t, args: %{message: String.t}, body: []}
  @spec explanation(%{message: String.t}, []) :: explanation_type
  def explanation(%{message: message}, []) do
    %Ast{kind: "explanation", args: %{message: message}, body: []}
  end

  @doc """
    updates a bot config
      args: %{data_label: String.t, number: integer}
      body: []
  """
  # TODO: FIXME: Botconfig updates
  @spec bot_config_update(%{data_label: String.t}, []) :: no_return
  def bot_config_update(%{data_label: label, number: val}, []) do
    Logger.warn ">> updating #{label} with #{val} is not implemented."
  end

  # TODO: FIXME: power off and reboot
  @doc """
    reboots your bot
      args: %{},
      body: []
  """
  @spec reboot(%{}, []) :: no_return
  def reboot(%{}, []), do: nil

  @doc """
    Powers off your bot
      args: %{},
      body: []
  """
  @spec power_off(%{}, []) :: no_return
  def power_off(%{}, []), do: nil

  @doc """
    updates mcu configs
      args: %{data_label: String.t, number: integer},
      body: []
  """
  @spec mcu_config_update(%{data_label: String.t, number: integer}, [])
    :: no_return
  def mcu_config_update(%{data_label: param_str, number: val}, []) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      "F22 P#{param_int} V#{val}" |> GHan.block_send
    else
      Logger.error ">> got an unrecognized param: #{param_str}"
    end
  end

  @doc """
    calibrates an axis:
      args: %{axis: "x" | "y" | "z"}
      body: []
  """
  @spec calibrate(%{axis: String.t}, []) :: no_return
  def calibrate(%{axis: axis}, []) do
    case axis do
      "x" -> "F14"
      "y" -> "F15"
      "z" -> "F16"
    end |> GHan.block_send
  end

  @doc """
    executes a thing
      args: %{sub_sequence_id: integer}
      body: []
  """
  @spec execute(%{sub_sequence_id: integer}, []) :: no_return
  def execute(%{sub_sequence_id: id}, []) do
    Farmbot.Sync.get_sequence(id)
    |> Ast.parse
    |> do_command
  end

  @doc """
    does absolutely nothing.
      args: %{},
      body: []
  """
  @spec nothing(%{}, []) :: nil
  def nothing(%{}, []), do: nil

  @doc """
    Executes a sequence. Be carefully.
      args: %{},
      body: [Ast.t]
  """
  @spec sequence(%{}, [Ast.t]) :: no_return
  def sequence(_, body) do
    for ast <- body do
      Logger.debug ">> doing: #{ast.kind}"
      do_command(ast)
      Logger.debug ">> done."
    end
  end

  @doc """
    Conditionally does something
      args: %{_else: Ast.t
              _then: Ast.t,
              lhs: String.t,
              op: "<" | ">" | "is" | "not",
              rhs: integer},
      body: []
  """
  @spec _if(%{}, []) :: no_return
  def _if(%{_else: else_, _then: then_, lhs: lhs, op: op, rhs: rhs }, []) do
    lhs
    |> eval_lhs
    |> eval_if(op, rhs, then_, else_)
  end

  # figure out what the user wanted
  @spec eval_lhs(String.t) :: integer | {:error, String.t}

  defp eval_lhs("pin" <> num) do
    num
    |> String.to_integer
    |> Farmbot.BotState.get_pin || {:error, "pin" <> num}
  end

  defp eval_lhs(axis) do
    [x, y, z] = Farmbot.BotState.get_current_pos
    case axis do
      "x" -> x
      "y" -> y
      "z" -> z
      _ -> {:error, axis} # its not an axis.
    end
  end

  @spec eval_if({:error, String.t} | integer, String.t, integer, Ast.t, Ast.t)
    :: no_return

  defp eval_if({:error, lhs}, _op, _rhs, _then, _else) do
    Logger.debug "Could not evaluate left hand side: #{lhs}"
  end

  defp eval_if(lhs, ">", rhs, then_, else_) do
    if lhs > rhs, do: do_command(then_), else: do_command(else_)
  end

  defp eval_if(lhs, "<", rhs, then_, else_) do
    if lhs < rhs, do: do_command(then_), else: do_command(else_)
  end

  defp eval_if(lhs, "is", rhs, then_, else_) do
    if lhs == rhs, do: do_command(then_), else: do_command(else_)
  end

  defp eval_if(lhs, "not", rhs, then_, else_) do
    if lhs != rhs, do: do_command(then_), else: do_command(else_)
  end

  defp eval_if(_, _, _, _, _), do: Logger.debug "bad if operator"

  @doc """
    Logs a message to some places
      args: %{},
      body: []
  """
  @type message_type :: String.t
  # "info"
  # "fun"
  # "warn"
  # "error"
  @type message_channel :: Farmbot.Logger.rpc_message_channel

  @spec send_message(%{message: String.t, message_type: message_type}, [Ast.t])
    :: no_return
  def send_message(%{message: m, message_type: m_type}, channels) do
    rendered = Mustache.render(m, get_message_stuff)
    Logger.debug ">> #{rendered}", type: m_type, channels: parse_channels(channels)
  end

  def get_message_stuff do
    [x, y, z] = Farmbot.BotState.get_current_pos
    %{x: x, y: y, z: z}
  end

  @spec parse_channels([Ast.t]) :: [message_channel]
  defp parse_channels(l) do
    {ch, _} = Enum.partition(l, fn(channel_ast) ->
      channel_ast.args["channel_name"]
    end)
    ch
  end

  @doc """
    writes an arduino pin
    args: %{
    pin_number: integer,
    pin_mode: integer,
    pin_value: integer
    },
    body: []
  """
  @typedoc """
    0 is digital
    1 is pwm
  """
  @type pin_mode :: 0 | 1
  @spec write_pin(%{pin_number: integer,
    pin_mode: pin_mode,
    pin_value: integer}, [])
  :: no_return
  def write_pin(%{pin_number: pin, pin_mode: mode, pin_value: val}, []) do
    # sets the pin mode in bot state.
    Farmbot.BotState.set_pin_mode(pin, mode)
    "F41 P#{pin} V#{val} M#{mode}" |> GHan.block_send
  end

  @doc """
    Reads an arduino pin
      args: %{
        data_label: String.t
        pin_number: integer,
        pin_mode: integer}
      body: []
  """
  @spec read_pin(%{data_label: String.t,
    pin_number: integer,
    pin_mode: pin_mode}, [])
  :: no_return
  def read_pin(%{data_label: _, pin_number: pin, pin_mode: mode}, []) do
    Farmbot.BotState.set_pin_mode(pin, mode)
    "F42 P#{pin} M#{mode}" |> GHan.block_send
  end

  @doc """
    sleeps for a number of milliseconds
      args: %{milliseconds: integer},
      body: []
  """
  @spec wait(%{milliseconds: integer}, []) :: no_return
  def wait(%{milliseconds: millis}, []), do: Process.sleep(millis)

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
      Logger.error ">> has no instruction for #{inspect ast}"
      :no_instruction
    end
  end
end
