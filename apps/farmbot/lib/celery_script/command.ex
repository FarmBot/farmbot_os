defmodule Farmbot.CeleryScript.Command do
  @moduledoc ~s"""
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
  alias Farmbot.System, as: FBSys
  alias Farmbot.Lib.Maths
  alias Amnesia
  use Amnesia
  alias Farmbot.Sync.Database.ToolSlot
  use ToolSlot
  use Counter, __MODULE__

  @digital 0
  # @pwm 1 # we don't use that yet, and its causing compiler warnings. Fix later
  @shrug "¯\\\\_(ツ)_/\¯"
  @type x :: integer
  @type y :: integer
  @type z :: integer
  @max_count 1_000

  # DISCLAIMER:
  # IF YOU SEE A HACK HERE RELATED TO A FIRMWARE COMMAND
  # IE: read_pin, write_pin, etc, DO NOT TRY TO FIX IT.
  # IT WORKS, AND DOES NOT CAUSE SIDE EFFECTS (unless it does ¯\_(ツ)_/¯)
  # (unless of course the arduino firmware is fixed.)

  # DISCLAIMER #2:
  # PLEASE MAKE SURE EVERYTHING IS TYPESPECED AND DOC COMMENENTED IN HERE.
  # SOME NODES, ARE HARD TO TEST,
  # AND SOME NODES CAN CAUSE CATASTROPHIC DISASTERS
  # ALSO THE COMPILER CAN'T PROPERLY CHECK SOMETHING BEING THAT THE ARGS ARE
  # NOT POSITIONAL.

  @doc ~s"""
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
  @lint {Credo.Check.Refactor.ABCSize, false}
  def move_absolute(%{speed: s, offset: offset, location: location}, []) do
    with %Ast{kind: "coordinate", args: %{x: xa, y: ya, z: za}, body: []} <-
            ast_to_coord(location),
         %Ast{kind: "coordinate", args: %{x: xb, y: yb, z: zb}, body: []} <-
            ast_to_coord(offset)
    do
      [x, y, z] =
        [Maths.mm_to_steps(xa + xb, spm(:x)),
         Maths.mm_to_steps(ya + yb, spm(:y)),
         Maths.mm_to_steps(za + zb, spm(:z))]
      "G00 X#{x} Y#{y} Z#{z} S#{s}" |> GHan.block_send
    else
      _ -> Logger.error ">> error doing Move absolute!"
    end
  end

  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end

  @doc ~s"""
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

  @doc ~s"""
    Convert an ast node to a coodinate or return :error.
  """
  @spec ast_to_coord(Ast.t) :: coordinate_ast | :error
  def ast_to_coord(ast)
  def ast_to_coord(%Ast{kind: "coordinate",
                        args: %{x: _x, y: _y, z: _z},
                        body: []} = already_done), do: already_done

  # NOTE(connor): don't change `tool_id_` back to `tool_id` what was happening
  # Amnesia builds local variables by the name of "tool_id", so it was looking
  # fortool_id == tool_id, which returned
  # all of them, because every toolslots tool_id
  # always equals that toolslots tool id lol
  @lint {Credo.Check.Refactor.PipeChainStart, false}
  def ast_to_coord(%Ast{kind: "tool", args: %{tool_id: tool_id_}, body: []}) do
    blah = Amnesia.transaction do
      ToolSlot.where(tool_id == tool_id_) |> Amnesia.Selection.values
    end
    case blah do
      [ts] -> coordinate(%{x: ts.x, y: ts.y, z: ts.z}, [])
      _ -> Logger.error ">> could not find tool_slot with tool_id: #{tool_id_}"
        :error
    end
  end

  # is this one a good idea?
  # there might be too expectations here: it could return the current position,
  # or 0
  def ast_to_coord(%Ast{kind: "nothing", args: _, body: _}) do
    coordinate(%{x: 0, y: 0, z: 0}, [])
  end

  def ast_to_coord(ast) do
    Logger.warn ">> no conversion from #{inspect ast} to coordinate"
    :error
  end

  @doc ~s"""
    coodinate
      args: %{x: integer, y: integer, z: integer}
      body: []
  """
  @type coord_args :: %{x: x, y: y, z: z}
  @type coordinate_ast :: %Ast{kind: String.t, args: coord_args, body: []}
  @spec coordinate(coord_args, []) :: coordinate_ast
  def coordinate(%{x: _x, y: _y, z: _z} = args, []) do
    %Ast{kind: "coordinate", args: args, body: []}
  end

  @doc ~s"""
    read_status
      args: %{},
      body: []
  """
  @spec read_status(%{}, []) :: no_return
  def read_status(%{}, []), do: Farmbot.BotState.Monitor.get_state

  @doc ~s"""
    sync
      args: %{},
      body: []
  """
  @spec sync(%{}, []) :: no_return
  def sync(%{}, []) do
    Logger.debug ">> is syncing!"
    case Farmbot.Sync.sync do
      {:ok, _} ->
        Logger.debug ">> synced!"
      {:error, reason} ->
        Logger.error ">> encountered an error syncing!: #{inspect reason}"
    end
  end
  @doc ~s"""
    Handles an RPC Request.
      args: %{label: String.t},
      body: [Ast.t,...]
  """
  @spec rpc_request(%{label: String.t}, [Ast.t, ...]) :: no_return
  def rpc_request(%{label: id}, more_stuff) do
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
    %{label: id} |> rpc_ok([]) |> Farmbot.Transport.emit
  end

  defp handle_req({_, failed}, id) do
    # there were some failed asts.
    %{label: id} |> rpc_error(failed) |> Farmbot.Transport.emit
  end

  @doc ~s"""
    Return for a valid Rpc Request
      args: %{label: String.t},
      body: []
  """
  @spec rpc_ok(%{label: String.t}, []) :: Ast.t
  def rpc_ok(%{label: id}, []) do
    %Ast{kind: "rpc_ok", args: %{label: id}, body: []}
  end

  @doc ~s"""
    bad return for a valid Rpc Request
      args: %{label: String.t},
      body: [Explanation]
  """
  @spec rpc_error(%{label: String.t}, [explanation_type]) :: Ast.t
  def rpc_error(%{label: id}, explanations) do
    %Ast{kind: "rpc_error", args: %{label: id}, body: explanations}
  end

  @doc ~s"""
    Explanation for an rpc error
      args: %{label: String.t},
      body: []
  """
  @type explanation_type ::
    %Ast{kind: String.t, args: %{message: String.t}, body: []}
  @spec explanation(%{message: String.t}, []) :: explanation_type
  def explanation(%{message: message}, []) do
    %Ast{kind: "explanation", args: %{message: message}, body: []}
  end

  @doc ~s"""
    reboots your bot
      args: %{},
      body: []
  """
  @spec reboot(%{}, []) :: no_return
  def reboot(%{}, []) do
    FBSys.reboot
  end

  @doc ~s"""
    Powers off your bot
      args: %{},
      body: []
  """
  @spec power_off(%{}, []) :: no_return
  def power_off(%{}, []) do
    FBSys.power_off
  end

  @type pair
    :: %Ast{kind: String.t, args: %{label: String.t, value: any}, body: []}
  @doc ~s"""
    Updates configuration on a package
      args: %{package: String.t},
      body: [Ast.t]
  """
  # MUCH IF SORRY ABOUT THAT
  @spec config_update(%{package: package}, [pair]) :: no_return
  def config_update(%{package: "arduino_firmware"}, config_pairs) do
    blah = pairs_to_tuples(config_pairs)
    for {param_str, val} <- blah do
      param_int = GParser.parse_param(param_str)
      if param_int do
        Logger.debug ">> is updating #{param_str}: #{val}"
        "F22 P#{param_int} V#{val}" |> GHan.block_send
        # HACK read the param back because sometimes the firmware decides
        # our param sets arent important enough to keep
        read_param(%{label: param_str}, [])
      else
        Logger.error ">> got an unrecognized param: #{param_str}"
      end
    end
  end

  def config_update(%{package: "farmbot_os"}, config_pairs) do
    blah = pairs_to_tuples(config_pairs)
    for {key, val} <- blah do
      Logger.debug ">> Updating #{key}: #{val}"
      Farmbot.BotState.update_config(key, val)
    end
  end

  @spec pairs_to_tuples([pair]) :: [tuple]
  defp pairs_to_tuples(config_pairs) do
    Enum.map(config_pairs, fn(%Ast{} = thing) ->
      {thing.args.label, thing.args.value}
    end)
  end

  @doc ~s"""
    calibrates an axis:
      args: %{axis: "x" | "y" | "z"}
      body: []
  """
  @spec calibrate(%{axis: String.t}, []) :: no_return
  @lint {Credo.Check.Refactor.PipeChainStart, false}
  def calibrate(%{axis: axis}, []) do
    case axis do
      "x" -> "F14"
      "y" -> "F15"
      "z" -> "F16"
    end |> GHan.block_send
  end

  @doc ~s"""
    Reads all mcu_params
      args: %{},
      body: []
  """
  @spec read_all_params(%{}, []) :: no_return
  def read_all_params(%{}, []), do: GHan.block_send("F20")

  @doc ~s"""
    Homes an axis
      args: %{axis: "x" | "y" | "z" | "all"},
      body: []
  """
  # HACK
  # F11 F12 F13 and G28 are all cureently broken.
  @type axis :: String.t # "x" | "y" | "z" | "all"
  @spec home(%{axis: axis}, []) :: no_return
  def home(%{axis: "all"}, []) do
    home(%{axis: "z"}, []) # <= Home z FIRST to prevent plant damage
    home(%{axis: "y"}, [])
    home(%{axis: "x"}, [])
  end

  def home(%{axis: axis}, [])
  when is_bitstring(axis) do
    [cur_x, cur_y, cur_z] = Farmbot.BotState.get_current_pos
    speed = 100
    blah = nothing(%{}, [])
    location =
      %{x: cur_x, y: cur_y, z: cur_z}
      |> Map.put(String.to_atom(axis), 0)
      |> coordinate([])
    move_absolute(%{speed: speed, location: location, offset: blah }, [])
  end

  @doc ~s"""
    executes a thing
      args: %{sequence_id_id: integer}
      body: []
  """
  @spec execute(%{sequence_id: integer}, []) :: no_return
  def execute(%{sequence_id: id}, []) do
    id
    |> Farmbot.Sync.get_sequence
    |> Ast.parse
    |> do_command
  end

  @doc ~s"""
    does absolutely nothing.
      args: %{},
      body: []
  """
  @type nothing_ast :: %Ast{kind: String.t, args: %{}, body: []}
  @spec nothing(%{}, []) :: nothing_ast
  def nothing(args, body), do: %Ast{kind: "nothing", args: args, body: body}

  @doc ~s"""
    Executes a sequence. Be carefully.
      args: %{},
      body: [Ast.t]
  """
  @spec sequence(%{}, [Ast.t]) :: no_return
  def sequence(_, body) do
    for ast <- body do
      check_count()
      Logger.debug ">> doing: #{ast.kind}"
      do_command(ast)
      Logger.debug ">> done."
      inc_count()
    end
    reset_count()
  end

  @doc ~s"""
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

  @doc ~s"""
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
    rendered = Mustache.render(m, get_message_stuff())
    Logger.debug ">> #{rendered}", type: m_type, channels: parse_channels(channels)
  end

  @spec get_message_stuff :: %{x: x, y: y, z: z}
  defp get_message_stuff do
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

  @doc ~s"""
    writes an arduino pin
    args: %{
    pin_number: integer,
    pin_mode: integer,
    pin_value: integer
    },
    body: []
  """
  @typedoc ~s"""
    0 is digital
    1 is pwm
  """
  @type digital :: 0
  @type pwm :: 1
  @type pin_mode :: digital | pwm
  @spec write_pin(%{pin_number: integer,
    pin_mode: pin_mode,
    pin_value: integer}, [])
  :: no_return
  def write_pin(%{pin_number: pin, pin_mode: mode, pin_value: val}, []) do
    # sets the pin mode in bot state.
    Farmbot.BotState.set_pin_mode(pin, mode)
    "F41 P#{pin} V#{val} M#{mode}" |> GHan.block_send
    # HACK read the pin back to make sure it worked
    read_pin(%{pin_number: pin, pin_mode: mode, label: "ack"}, [])
    # HACK the above hack doesnt work some times so we just force it to work.
    Farmbot.BotState.set_pin_value(pin, val)
  end

  @doc ~s"""
    Reads an arduino pin
      args: %{
        label: String.t
        pin_number: integer,
        pin_mode: integer}
      body: []
  """
  @spec read_pin(%{label: String.t,
    pin_number: integer,
    pin_mode: pin_mode}, [])
  :: no_return
  def read_pin(%{label: _, pin_number: pin, pin_mode: mode}, []) do
    Farmbot.BotState.set_pin_mode(pin, mode)
    "F42 P#{pin} M#{mode}" |> GHan.block_send
  end

  @doc ~s"""
    toggles a digital pin
      args: %{pin_number: String.t},
      body: []
  """
  @spec toggle_pin(%{pin_number: String.t}, []) :: no_return
  def toggle_pin(%{pin_number: pin}, []) do
    # if we are trying to toggle an analog pin, make it digital i guess?
    # if it was analog, it will result in becoming 0
    Farmbot.BotState.set_pin_mode(pin, @digital)
    %{mode: @digital, value: val} = Farmbot.BotState.get_pin(pin)
    do_toggle(pin, val)
  end

  @spec do_toggle(String.t, integer) :: no_return
  def do_toggle(pin, val) do
    case val do
      # if it was off turn it on
      0 -> write_pin(%{pin_number: pin, pin_mode: @digital, pin_value: 1}, [])
      # if it was on (or analog) turn it off. (for safetey)
      _ -> write_pin(%{pin_number: pin, pin_mode: @digital, pin_value: 0}, [])
    end
  end

  @doc ~s"""
    sleeps for a number of milliseconds
      args: %{milliseconds: integer},
      body: []
  """
  @spec wait(%{milliseconds: integer}, []) :: no_return
  def wait(%{milliseconds: millis}, []), do: Process.sleep(millis)

  @doc ~s"""
    Checks updates for given package
      args: %{package: "arduino_firmware" | "farmbot_os"},
      body: []
  """
  @type package :: String.t # "arduino_firmware" | "farmbot_os"
  @spec check_updates(%{package: package}, []) :: no_return
  def check_updates(%{package: package}, []) do
    case package do
      "arduino_firmware" ->
        # TODO(Connor): Move this, and its contents somewhere else
        Farmbot.Updates.Handler.check_and_download_updates(:fw)
      "farmbot_os" ->
        Farmbot.System.Updates.check_and_download_updates()

      u -> Logger.debug ">> got a request to check updates for an " <>
        "unrecognized package: #{u}"
    end
  end

  @doc ~s"""
    Reads a param value
      args: %{label: String.t}
      body: []
  """
  @spec read_param(%{label: String.t}, []) :: no_return
  def read_param(%{label: param_str}, []) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      GHan.block_send("F21 P#{param_int}")
    else
      Logger.error ">> got unknown param: #{param_str}"
    end
  end

  @doc ~s"""
    Sends a warning message. Used for denoting hax and what not
      args: %{message: String.t}
      body: []
  """
  @spec shrug(%{messsage: String.t}, []) :: no_return
  def shrug(%{message: str}, []) do
    send_message(%{message: str <> @shrug, message_type: :warn}, [])
  end

  @doc ~s"""
    Locks the bot from movement until unlocked
      args: %{},
      body: []
  """
  @spec emergency_lock(%{}, []) :: no_return
  def emergency_lock(%{}, []) do
    # HACK / BUG the arduino firmware won't E stop for some reason, so all
    # it's state gets wiped out. One day when the firmware works again
    # we can reimplement this
    Farmbot.Serial.Handler.e_stop
    shrug(%{message: ">> is lost. Probably a good idea to reboot."}, [])
  end

  @doc ~s"""
    unlocks the bot allowing movement again.
      args: %{},
      body: []
  """
  @spec emergency_unlock(%{}, []) :: no_return
  def emergency_unlock(%{}, []) do
    Logger.warn ">> needs to be rebooted"
  end

  @doc ~s"""
    Factory resets bot.
  """
  @spec factory_reset(%{}, []) :: no_return
  def factory_reset(%{}, []) do
    Logger.warn(">> Going down for factory reset in 5 seconds!")
    spawn fn ->
      Process.sleep 5000
      Farmbot.System.factory_reset()
    end
  end

  @doc ~s"""
    Executes a farmware
      args: %{label: String.t},
      body: [pair]
    NOTE this is a shortcut to starting a process by uuid
  """
  @spec execute_script(%{label: String.t}, [pair]) :: no_return
  def execute_script(%{label: "image-capture"}, _env_vars) do
    Logger.debug ">> Is doing hax!!@@"
    Farmbot.Camera.capture()
  end

  def execute_script(%{label: farmware}, env_vars) do
    set_user_env(%{}, env_vars)
    Farmbot.BotState.ProcessTracker.lookup(:farmware, farmware)
    |> Farmbot.BotState.ProcessTracker.start_process()
  end

  @doc """
    Starts a FarmProcess
  """
  def start_process(%{label: uuid}, []) do
    Farmbot.BotState.ProcessTracker.start_process(uuid)
  end

  @doc ~s"""
    Sets a bunch of user environment variables for farmware
      args: %{},
      body: [pair]
  """
  @spec set_user_env(%{}, [pair]) :: no_return
  @lint {Credo.Check.Refactor.PipeChainStart, false}
  def set_user_env(%{}, env_pairs) do
     pairs_to_tuples(env_pairs)
     |> Map.new
     |> Farmbot.BotState.set_user_env
  end

  @doc ~s"""
    Executes an ast node.
  """
  @spec do_command(Ast.t) :: :no_instruction | any
  def do_command(%Ast{} = ast) do
    check_count()
    fun_name = String.to_atom(ast.kind)
    # print the comment if it exists
    if ast.comment, do: Logger.debug ">> [#{fun_name}] - #{ast.comment}"

    if function_exported?(__MODULE__, fun_name, 2) do
      Kernel.apply(__MODULE__, fun_name, [ast.args, ast.body])
      dec_count()
    else
      Logger.error ">> has no instruction for #{inspect ast}"
      :no_instruction
    end
  end

  defp check_count() do
    if get_count() < @max_count  do
      inc_count()
    else
      Logger.error ">> COUNT TOO HIGH!"
      reset_count()
      raise("TO MUCH RECURSION")
    end
  end
end
