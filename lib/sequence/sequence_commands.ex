defmodule SequenceCommands do
  require Logger
  def do_command({"move_absolute", %{"x" => x, "y" => y, "z" => z, "speed" => s}}, _pid)
  when is_integer(x)
   and is_integer(y)
   and is_integer(z)
   and is_integer(s)
  do
    Command.move_absolute(x,y,z,s)
  end

  def do_command({"move_relative", %{"x" => x, "y" => y, "z" => z, "speed" => s}}, _pid)
   when is_integer(x)
    and is_integer(y)
    and is_integer(z)
    and is_integer(s)
  do
    Command.move_relative(%{x: x, y: y, z: z, speed: s})
  end

  def do_command({"write_pin", %{"pin_number" => pin, "pin_value" => value, "pin_mode" => mode}}, _pid) do
    Command.write_pin(pin, value, mode)
  end

  def do_command({"read_pin", %{"pin_number" => pin, "data_label" => variable_name}}, pid) do
    Command.read_pin(pin)
    v = BotStatus.get_pin(pin)
    GenServer.call(pid, {:set_var, variable_name, v})
  end

  def do_command({"wait", %{"milliseconds" => milis}}, _pid) when is_integer(milis) do
    Process.sleep(milis)
  end

  def do_command({"send_message", %{"message" => message}}, _pid) when is_bitstring(message) do
    RPCMessageHandler.log(message)
  end

  def do_command({"execute", %{"sub_sequence_id" => id}}, _pid) when is_integer(id) do
    Sequencer.do_sequence(BotSync.get_sequence(id))
  end

  def do_command({"if_statement", %{"lhs" => lhs, "op" => op, "rhs" => rhs, "sub_sequence_id" => seq_id}}, pid)
   when is_bitstring(lhs) and is_bitstring(op) and is_integer(rhs) do
    case(eval_if({get_lhs(lhs), op, rhs})) do
      true -> do_command({"execute", %{"sub_sequence_id" => seq_id}}, pid)
      false -> :false_eval
    end
  end

  def do_command({kind, args}, _pid) do
    log_msg = "#{kind} with params: #{inspect args} is not implemented or malformed"
    Logger.debug(log_msg)
    RPCMessageHandler.log(log_msg)
  end

  def eval_if({lhs, ">", rhs}) when is_integer(lhs) and is_integer(rhs) do
    case lhs > rhs do
      true -> true
      _ -> false
    end
  end

  def eval_if({lhs, "<", rhs}) when is_integer(lhs) and is_integer(rhs) do
    case lhs < rhs do
      true -> true
      _ -> false
    end
  end

  def eval_if({lhs, "is", rhs}) when is_integer(lhs) and is_integer(rhs) do
    case lhs == rhs do
      true -> true
      _ -> false
    end
  end

  def eval_if({lhs, "not", rhs}) when is_integer(lhs) and is_integer(rhs) do
    case lhs != rhs do
      true -> true
      _ -> false
    end
  end

  def eval_if({nil, _, _}) do
    Logger.debug("Couldn't evaluate lhs")
    false
  end

  def eval_if({lhs, un_supported, rhs}) when is_integer(lhs) and is_integer(rhs)  do
    Logger.debug("#{un_supported} is not a supported operator")
    false
  end

  def eval_if(_) do
    Logger.debug("couldnt evaluate if statement.")
    false
  end

  def get_lhs("x") do  [x,_,_] = BotStatus.get_current_pos; x end
  def get_lhs("y") do  [_,y,_] = BotStatus.get_current_pos; y end
  def get_lhs("z") do  [_,_,z] = BotStatus.get_current_pos; z end
  def get_lhs("s") do BotStatus.get_speed end
  def get_lhs("busy") do case(BotStatus.busy?) do true -> 1; _ -> 0 end end
  def get_lhs("time")  do :os.system_time end
  def get_lhs("pin0")  do BotStatus.get_pin("pin0")   end
  def get_lhs("pin1")  do BotStatus.get_pin("pin1")   end
  def get_lhs("pin2")  do BotStatus.get_pin("pin2")   end
  def get_lhs("pin3")  do BotStatus.get_pin("pin3")   end
  def get_lhs("pin4")  do BotStatus.get_pin("pin4")   end
  def get_lhs("pin5")  do BotStatus.get_pin("pin5")   end
  def get_lhs("pin6")  do BotStatus.get_pin("pin6")   end
  def get_lhs("pin7")  do BotStatus.get_pin("pin7")   end
  def get_lhs("pin8")  do BotStatus.get_pin("pin8")   end
  def get_lhs("pin9")  do BotStatus.get_pin("pin9")   end
  def get_lhs("pin10") do BotStatus.get_pin("pin10")  end
  def get_lhs("pin11") do BotStatus.get_pin("pin11")  end
  def get_lhs("pin12") do BotStatus.get_pin("pin12")  end
  def get_lhs("pin13") do BotStatus.get_pin("pin13")  end
  def get_lhs(param) when is_bitstring(param) do Gcode.parse_param(param) |> BotStatus.get_param end
  def get_lhs(_) do nil end
end
