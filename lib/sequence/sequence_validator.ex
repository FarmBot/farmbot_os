defmodule SequenceValidator do
  def validate(args, body)
    when is_map(args) and is_list(body) do
    case validate_args(args) do
      {:valid, arg_warnings, arg_seconds}
        -> case validate_body(body, arg_seconds ) do
          {:valid, body_warnings, body_seconds} -> {:valid, arg_warnings ++ body_warnings, arg_seconds + body_seconds }
          {:error, reason} -> {:error, reason}
        end
      {:error, reason}
        -> {:error, reason}
    end
  end

  def validate(_args, _body) do
    reason = "bad type of args or body. "
    {:error, reason}
  end

  def validate_args(args) when is_map(args) do
    {:valid, [], 0}
  end

  def validate_body(body, seconds) when is_list(body) and is_integer(seconds) do
    step = List.first(body)
    validate_body(step, body -- [step], [], seconds)
  end

  def validate_body(step, [], warnings, total_seconds) do
    case validate_step(step) do
      {:valid, step_warnings, step_seconds} -> {:valid, warnings ++ step_warnings, step_seconds + total_seconds }
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_body(step, rest, warnings, total_seconds ) do
    next_step = List.first(rest)
    case validate_step(step) do
      {:valid, step_warnings, step_seconds} ->
        validate_body(next_step, rest -- [next_step], warnings ++ step_warnings, total_seconds + step_seconds)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_step(%{"kind" => "move_absolute", "args" => %{"x" => x, "y" => y, "z" => z, "speed" => s}}) do
    case validate_body([x,y,z,s],0) do
      {:valid, step_warnings, step_seconds} ->
        r_x = get_int(x)
        r_y = get_int(y)
        r_z = get_int(z)
        r_s = get_int(s)
        [b_x,b_y,b_z] = BotStatus.get_current_pos
        sec = get_time_for_move({r_x,r_y,r_z}, {b_x,b_y,b_z}, s)
        {:valid, step_warnings, step_seconds + sec}
      {:error, reason} -> {:error, reason}
    end
  end
  def validate_step(%{"kind" => "move_absolute", "args" => _args}) do
    {:error, "Bad Args for move_absolute"}
  end

  def validate_step(%{"kind" => "move_relative", "args" => %{"x" => x, "y" => y, "z" => z, "speed" => s}}) do
    case validate_body([x,y,z,s],0) do
      {:valid, step_warnings, step_seconds} ->
        r_x = get_int(x)
        r_y = get_int(y)
        r_z = get_int(z)
        r_s = get_int(s)
        [b_x,b_y,b_z] = BotStatus.get_current_pos
        sec = get_time_for_move({r_x,r_y,r_z}, {b_x,b_y,b_z}, s)
        {:valid, step_warnings, step_seconds + sec}
      {:error, reason} -> {:error, reason}
    end
  end
  def validate_step(%{"kind" => "move_relative", "args" => _args}) do
    {:error, "Bad Args for move_relative"}
  end

  def validate_step(%{"kind" => "write_pin", "args" => %{"pin_number" => pin, "pin_value" => value, "pin_mode" => mode}}) do
    validate_body([pin, value, mode],1)
  end
  def validate_step(%{"kind" => "write_pin", "args" => _args}) do
    {:error, "Bad Args for write_pin"}
  end

  def validate_step(%{"kind" => "read_pin", "args" => %{"pin_number" => pin, "data_label" => variable_name, "pin_mode" => mode}}) do
    validate_body([pin, variable_name, mode],1)
  end
  def validate_step(%{"kind" => "read_pin", "args" => _args}) do
    {:error, "Bad Args for read_pin"}
  end

  def validate_step(%{"kind" => "wait", "args" => %{"milliseconds" => milis}}) do
    case validate_body([milis],0) do
      {:valid, warnings, 0} ->
        r_milis = get_int(milis)
        sec = r_milis / 1000
        {:valid, warnings, sec}
        {:error, reason} -> {:error, reason}
    end
  end
  def validate_step(%{"kind" => "wait", "args" => _args}) do
    {:error, "Bad Args for wait"}
  end

  def validate_step(%{"kind" => "send_message", "args" => %{"message" => message}}) do
    validate_body([message],1)
  end
  def validate_step(%{"kind" => "send_message", "args" => _args}) do
    {:error, "Bad Args for send_message"}
  end

  def validate_step(%{"kind" => "execute", "args" => %{"sub_sequence_id" => seq_id}}) do
    case validate_body([seq_id],0) do
      {:valid, warnings, 0} ->
        r_id = get_int(seq_id)
        next_seq = BotSync.get_sequence(r_id)
        seq_args = Map.get(next_seq, "args")
        seq_body = Map.get(next_seq, "body")
        validate(seq_args, seq_body)
      {:error, reason} -> {:error, reason}
    end
  end
  def validate_step(%{"kind" => "execute", "args" => _args}) do
    {:error, "Bad Args for execute"}
  end

  def validate_step(%{"kind" => "math", "args" => %{"lhs" => lhs, "op" => op, "rhs" => rhs}}) do
    validate_body([lhs, op, rhs],0)
  end
  def validate_step(%{"kind" => "math", "args" => _args}) do
    {:error, "Bad Args for math"}
  end

  def validate_step(%{"kind" => "if_statement", "args" => %{"lhs" => lhs, "op" => op, "rhs" => rhs, "sub_sequence_id" => ssid}}) do
    validate_body([lhs, op, rhs, ssid],0)
  end
  def validate_step(%{"kind" => "if_statement", "args" => _args}) do
    {:error, "Bad Args for if_statement"}
  end

  def validate_step(%{"kind" => "get_var", "args" => %{"data_label" => id}}) do
    validate_body([id],1)
  end

  def validate_step(%{"kind" => "get_var", "args" => _args}) do
    {:error, "Bad Args for get_var"}
  end

  def validate_step(%{"kind" => "set_var", "args" => %{"data_label" => id, "data_value" => value}}) do
    validate_body([id, value],1)
  end

  def validate_step(%{"kind" => "set_var", "args" => _args}) do
    {:error, "Bad Args for set_var"}
  end

  def validate_step(%{"kind" => "literal", "args" => %{"data_type" => "string", "data_value" => str}})
   when is_bitstring(str) do
    {:valid, [],0}
  end

  def validate_step(%{"kind" => "literal", "args" => %{"data_type" => "integer", "data_value" => intstr}})
   when is_bitstring(intstr) do
      case Integer.parse(intstr) do
        {_number, ""} -> {:valid, [], 0}
        {_number, str} -> {:valid, ["#{str} was found in integer."], 0}
        :error -> {:error, "could not parse integer"}
      end
  end

  def validate_step(%{"kind" => "literal", "args" => %{"data_type" => "integer", "data_value" => int}})
    when is_integer(int) do
      {:valid, ["integer literal data_value should be a string"], 0}
  end
  def validate_step(%{"kind" => "literal", "args" => _args}) do
    {:error, "Bad Args for literal"}
  end

  def validate_step(value) when is_bitstring(value) do
    {:valid, ["Please use literal nodes for strings"], 0}
  end

  def validate_step(value) when is_integer(value) do
    {:valid, ["Please use literal nodes for integers"], 0}
  end

  def validate_step(step) do
    {:error, "Step: #{inspect step} has no validator. This Could mean it is unimplemented"}
  end

  def get_int(value) when is_integer(value) do
    value
  end

  def get_int(%{"kind" => "literal", "args" => %{"data_type" => "integer", "data_value" => int}})
  when is_integer(int) do
    int
  end

  def get_int(%{"kind" => "literal", "args" => %{"data_type" => "integer", "data_value" => int}})
  when is_bitstring(int) do
    String.to_integer(int)
  end

  @doc """
    Calculates how long it will take to move from point a to point b at speed
  """
  def get_time_for_move({a_x,a_y,a_z}, {b_x,b_y,b_z}, _steps_per_second) do
    # STEPS PER SECOND isnt being used anymore.
    x_distance = (a_x - b_x) #steps
    y_distance = (a_y - b_y)
    z_distance = (a_z - b_z)
    distance_in_steps = :math.sqrt((:math.pow(x_distance, 2) + :math.pow(y_distance, 2) + :math.pow(z_distance, 2)))
    distance_in_steps / 1500
  end
end
