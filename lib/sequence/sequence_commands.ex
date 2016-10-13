defmodule SequenceCommands do
  require Logger
  def do_command({"move_absolute", %{"x" => x, "y" => y, "z" => z, "speed" => s}}, pid)
  when is_map(x) or is_integer(x)
   and is_map(y) or is_integer(y)
   and is_map(z) or is_integer(z)
   and is_map(s) or is_integer(s)
  do
    rx = do_command(x, pid)
    ry = do_command(y, pid)
    rz = do_command(z, pid)
    rs = do_command(s, pid)
    Command.move_absolute(rx,ry,rz,rs)
  end

  def do_command({"move_relative", %{"x" => x, "y" => y, "z" => z, "speed" => s}}, pid)
  when is_map(x) or is_integer(x)
   and is_map(y) or is_integer(y)
   and is_map(z) or is_integer(z)
   and is_map(s) or is_integer(s)
  do
    rx = do_command(x, pid)
    ry = do_command(y, pid)
    rz = do_command(z, pid)
    rs = do_command(s, pid)
    Command.move_relative(%{x: rx, y: ry, z: rz, speed: rs})
  end

  def do_command({"write_pin", %{"pin_number" => pin, "pin_value" => value, "pin_mode" => mode}}, pid)
  when is_map(pin) or is_integer(pin)
   and is_map(value) or is_integer(value)
   and is_map(mode) or is_integer(mode)
  do
    rpin = do_command(pin, pid)
    rvalue = do_command(value, pid)
    rmode = do_command(mode, pid)
    Command.write_pin(rpin, rvalue, rmode)
  end

  def do_command({"read_pin", %{"pin_number" => pin, "data_label" => variable_name}}, pid)
  when is_map(pin) or is_integer(pin)
   and is_map(variable_name) or is_bitstring(variable_name)
  do
    rpin = do_command(pin, pid)
    rvar = do_command(variable_name, pid)
    Command.read_pin(rpin)
    v = BotStatus.get_pin(rpin)
    GenServer.call(pid, {:set_var, rvar, v})
  end

  def do_command({"wait", %{"milliseconds" => milis}}, pid)
  when is_map(milis) or is_integer(milis) do
    rmilis = do_command(milis, pid)
    Process.sleep(rmilis)
  end

  # SHHHH
  def do_command({"send_message", %{"message" => "secret "<>message}}, _pid) do
    case Poison.decode(message) do
      {:ok, json} ->
        RPCMessageHandler.log("you found a secret")
        RPCMessageHandler.handle_rpc(json)
      _ -> nil
    end
  end

  def do_command({"send_message", %{"message" => "channel "<>message}}, pid)
  when is_bitstring(message) do
    vars = GenServer.call(pid, :get_all_vars)
    {channel, rmessage} = case message do
      "error_ticker"<>m -> {"error_ticker", m}
      "ticker "<>m -> {"ticker", m}
      "error_toast "<>m -> {"error_toast", m}
      "success_toast "<>m -> {"success_toast", m}
      "warning_toast "<>m -> {"warning_toast", m}
      m -> {"logger ", m}
    end
    rendered = Mustache.render(rmessage, vars)
    Logger.debug(rendered<>" #{inspect channel}")
    RPCMessageHandler.log(rendered, channel)
  end

  def do_command({"send_message", %{"message" => message}}, pid)
  when is_bitstring(message) do
    vars = GenServer.call(pid, :get_all_vars)
    rendered = Mustache.render(message, vars)
    Logger.debug(rendered)
    RPCMessageHandler.log(rendered)
  end

  # This is just for testing
  def do_command({"execute", %{"sub_sequence_id" => more_nodes}}, pid) when is_list(more_nodes) do
    Logger.debug("executing more things")
    Sequencer.execute(more_nodes, pid)
  end

  def do_command({"execute", %{"sub_sequence_id" => seq_id}}, pid) when is_map(seq_id) or is_integer(seq_id) do
    rid = do_command(seq_id,pid)
    s = BotSync.get_sequence(rid)
    body = Map.get(s, "body")
    Sequencer.execute(body, pid)
  end

  def do_command({"math", %{"lhs" => lhs, "op" => op, "rhs" => rhs}},pid)
    when is_bitstring(op) do
      do_math({
        do_command(lhs, pid),
        op,
        do_command(rhs, pid),
      })
  end

  def do_command({"if_statement", %{"lhs" => lhs, "op" => op, "rhs" => rhs, "sub_sequence_id" => ssid}}, pid)
    when is_bitstring(op) do
      l = cond do
        is_bitstring(lhs) ->
          vars = GenServer.call(pid, :get_all_vars)
          Map.get(vars, String.to_atom(lhs))
        is_integer(lhs) -> lhs
        true -> do_command(lhs, pid)
      end
      Logger.debug(l)
      rlhs = do_command(l, pid)
      rrhs = do_command(rhs, pid)
      case eval_if({rlhs, op, rrhs}) do
        true  -> do_command({"execute", %{"sub_sequence_id" => ssid}}, pid)
        false -> Logger.debug("if(#{rlhs} #{op} #{rrhs}) evaluated false")
      end
  end

  def do_command({"get_var", %{"data_label" => id}}, pid)
  when is_map(id) do
    rid = do_command({Map.get(id, "kind"), Map.get(id, "args")}, pid)
    GenServer.call(pid, {:get_var, rid})
  end

  def do_command({"set_var", %{"data_label" => id, "data_value" => value}}, pid)
    when is_map(id) and is_map(value) do
    rid = do_command(id, pid)
    rvalue = do_command(value, pid)
    Logger.debug("setting #{rid} to #{rvalue}")
    GenServer.call(pid, {:set_var, rid, rvalue})
  end

  def do_command({"literal", %{"data_type" => "string", "data_value" => str}}, _pid) when is_bitstring(str) do
    Logger.debug("string literal: #{str}")
    str
  end

  def do_command({"literal", %{"data_type" => "integer", "data_value" => intstr}}, _pid) when is_bitstring(intstr) do
    Logger.debug("integer literal: #{intstr} (from string)")
    String.to_integer(intstr)
  end

  def do_command({"literal", %{"data_type" => "integer", "data_value" => int}}, _pid) when is_integer(int) do
    Logger.debug("integer literal: #{int} (from int)")
    int
  end

  def do_command({"literal", %{"data_type" => type, "data_value" => val}}, pid) when is_map(type) and is_map(val) do
    Logger.debug("infering type: #{type} for #{val}")
    rtype = do_command(type, pid)
    rval = do_command(val, pid)
    case infer_type(rtype) do
      :integer -> do_command({"literal", %{"data_type" => "integer", "data_value" => rval}}, pid)
      :string -> do_command({"literal", %{"data_type" => "string", "data_value" => rval}}, pid)
    end
  end

  # until the api can do ast nodes for arguments
  def do_command(val, _pid)
    when is_integer(val) do
      val
  end

  # until the api can do ast nodes for arguments
  def do_command(val, _pid)
    when is_bitstring(val) do
      val
  end

  def do_command(nil, _pid) do
    nil
  end

  def do_command(%{"kind" => kind, "args" => args}, pid) when is_bitstring kind and is_map(args) do
    do_command({kind, args}, pid)
  end

  def do_command({kind, args}, _pid) do
    log_msg = "#{kind} with params: #{inspect args} is not implemented or malformed"
    Logger.debug(log_msg)
    RPCMessageHandler.log(log_msg)
  end

  def infer_type(typestr) when is_bitstring(typestr) do
    cond do
      typestr == "string" -> :string
      typestr == "integer" -> :integer
    end
  end

  def do_math({lhs, "+", rhs})
    when is_integer(lhs) and is_integer(rhs) do
    lhs + rhs
  end

  def do_math({lhs, "-", rhs})
    when is_integer(lhs) and is_integer(rhs) do
    lhs - rhs
  end

  def do_math({lhs, "/", rhs})
    when is_integer(lhs) and is_integer(rhs) do
    lhs / rhs
  end

  def do_math({lhs, "*", rhs})
    when is_integer(lhs) and is_integer(rhs) do
    lhs * rhs
  end

  def do_math(params) do
    Logger.debug("couldnt do math with #{inspect params}")
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

  def eval_if({lhs, un_supported, rhs}) when is_integer(lhs) and is_integer(rhs)  do
    Logger.debug("#{un_supported} is not a supported operator")
    false
  end

  def eval_if(params) do
    Logger.debug("couldnt evaluate if statement.")
    IO.inspect(params)
    false
  end

  def eval_side("x", _pid) do  [x,_,_] = BotStatus.get_current_pos; x end
  def eval_side("y", _pid) do  [_,y,_] = BotStatus.get_current_pos; y end
  def eval_side("z", _pid) do  [_,_,z] = BotStatus.get_current_pos; z end
  def eval_side("s", _pid) do BotStatus.get_speed end
  def eval_side("busy", _pid) do case(BotStatus.busy?) do true -> 1; _ -> 0 end end
  def eval_side("time", _pid)  do :os.system_time end
  def eval_side("pin0", _pid)  do BotStatus.get_pin("pin0")   end
  def eval_side("pin1", _pid)  do BotStatus.get_pin("pin1")   end
  def eval_side("pin2", _pid)  do BotStatus.get_pin("pin2")   end
  def eval_side("pin3", _pid)  do BotStatus.get_pin("pin3")   end
  def eval_side("pin4", _pid)  do BotStatus.get_pin("pin4")   end
  def eval_side("pin5", _pid)  do BotStatus.get_pin("pin5")   end
  def eval_side("pin6", _pid)  do BotStatus.get_pin("pin6")   end
  def eval_side("pin7", _pid)  do BotStatus.get_pin("pin7")   end
  def eval_side("pin8", _pid)  do BotStatus.get_pin("pin8")   end
  def eval_side("pin9", _pid)  do BotStatus.get_pin("pin9")   end
  def eval_side("pin10", _pid) do BotStatus.get_pin("pin10")  end
  def eval_side("pin11", _pid) do BotStatus.get_pin("pin11")  end
  def eval_side("pin12", _pid) do BotStatus.get_pin("pin12")  end
  def eval_side("pin13", _pid) do BotStatus.get_pin("pin13")  end
  def eval_side(maybe_param, _pid) when is_bitstring(maybe_param) do
    p = Gcode.parse_param(maybe_param) |> BotStatus.get_param
    cond do
      is_integer(p) -> p
      true -> Logger.debug("#{p} is not an integer"); nil
    end
  end
end
