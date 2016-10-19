defmodule SequenceInstructionSet_0 do
  require Logger
  def create_instruction_set(%{"tag" => 0, "args" => allowed_args_list, "nodes" => allowed_nodes_list}) do
    initial =
      "
      defmodule Corpus_0 do
        use GenServer
        require Logger
        def start_link(args) do
          GenServer.start_link(__MODULE__, args, name: __MODULE__)
        end

        def init(parent) do
          {:ok, parent}
        end
      "
    Module.create(SiS, create_instructions(initial, allowed_args_list, allowed_nodes_list ), Macro.Env.location(__ENV__))
  end

  def create_instructions(initial, arg_list, node_list) when is_list(arg_list) and is_list(node_list) do
    initial
    <>create_arg_instructions(arg_list, "")
    <>create_node_instructions(node_list, "")
    <>"
      def terminate(:normal, parent) do
        :ok
      end

      def terminate(reason, parent) do
        Logger.debug(\"Corpus died.\")
        IO.inspect(reason)
        IO.inspect(parent)
      end
    end" |> Code.string_to_quoted!
  end

  def create_arg_instructions([], str) do
    str
  end

  def create_arg_instructions(arg_list, old) when is_list arg_list do
    arg = List.first(arg_list) || ""
    arg_code_str = create_arg_instructions(arg)
    create_arg_instructions(arg_list -- [arg], old<>" "<>arg_code_str)
  end

  def create_arg_instructions(%{"name" => name, "allowed_values" => allowed_values})
  when  is_bitstring(name) and is_list(allowed_values) do
    create_arg_instruction(name, allowed_values, "")
  end

  def create_arg_instruction(_name, [], str ) do
    str
  end

  def create_arg_instruction(name, types, old) do
    type = List.first(types)
    check =
    case type do
      "integer" -> "when is_integer(value)"
      "string"  -> "when is_bitstring(value)"
      # "node"    -> "when is_map(value)"
    end
    new =
      "
      def #{name}(value) #{check} do
        value
      end
      "
    create_arg_instruction(name, types -- [type], old<>new)
  end

  def create_node_instructions([], str) do
    str
  end

  def create_node_instructions(arg_list, old) when is_list arg_list do
    arg = List.first(arg_list) || ""
    arg_code_str = create_node_instructions(arg)
    create_node_instructions(arg_list -- [arg], old<>" "<>arg_code_str)
  end

  def create_node_instructions(%{"name" => "move_absolute", "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_list(allowed_args) and is_list(allowed_body_types) do
    args = create_arg_map(allowed_args)
    "
    def handle_cast({ \"move_absolute\", %{#{args}} }, parent) do
      Command.move_absolute(x(x),y(y),z(z),speed(speed))
      SequencerVM.tick(parent)
      {:noreply, parent}
    end

    def handle_cast({\"move_absolute\", _}, parent) do
      RPCMessageHandler.log(\"bad params\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  def create_node_instructions(%{"name" => "move_relative", "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_list(allowed_args) and is_list(allowed_body_types) do
    args = create_arg_map(allowed_args)
    "
    def handle_cast({ \"move_relative\", %{#{args}}}, parent) do
      Command.move_relative(%{x: x(x), y: y(y), z: z(z), speed: speed(speed)})
      SequencerVM.tick(parent)
      {:noreply, parent}
    end

    def handle_cast({\"move_relative\", _}, parent) do
      RPCMessageHandler.log(\"bad params\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  def create_node_instructions(%{"name" => "write_pin", "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_list(allowed_args) and is_list(allowed_body_types) do
    args = create_arg_map(allowed_args)
    "
    def handle_cast({\"write_pin\", %{#{args}}}, parent) do
      Command.write_pin(pin_number(pin_number),
                        pin_value(pin_value),
                        pin_mode(pin_mode))
      SequencerVM.tick(parent)
      {:noreply, parent}
    end

    def handle_cast({\"write_pin\", _}, parent) do
      RPCMessageHandler.log(\"bad params\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  def create_node_instructions(%{"name" => "read_pin", "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_list(allowed_args) and is_list(allowed_body_types) do
    args = create_arg_map(allowed_args)
    "
    def handle_cast({\"read_pin\", %{#{args}}}, parent) do
      Command.read_pin( pin_number(pin_number),
                        pin_mode(pin_mode) )
      v = BotStatus.get_pin(pin_number(pin_number))
      GenServer.cast(parent, {:set_var, data_label(data_label), v})
      SequencerVM.tick(parent)
      {:noreply, parent}
    end

    def handle_cast({\"read_pin\", _}, parent) do
      RPCMessageHandler.log(\"bad params\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  def create_node_instructions(%{"name" => "wait", "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_list(allowed_args) and is_list(allowed_body_types) do
    args = create_arg_map(allowed_args)
    "
    def handle_cast({\"wait\", %{#{args}}}, parent) do
      Process.sleep( milliseconds(milliseconds) )
      SequencerVM.tick(parent)
      {:noreply, parent}
    end

    def handle_cast({\"wait\", _}, parent) do
      RPCMessageHandler.log(\"bad params\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  def create_node_instructions(%{"name" => "send_message", "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_list(allowed_args) and is_list(allowed_body_types) do
    args = create_arg_map(allowed_args)
    "
    def handle_cast({\"send_message\", %{#{args}}}, parent) do
      vars = GenServer.call(parent, :get_all_vars)
      case message(message) do
        \"channel \"<>channel_message ->
          {channel, rmessage} = case channel_message do
            \"error_ticker\"<>m   -> {\"error_ticker\", m}
            \"ticker \"<>m        -> {\"ticker\", m}
            \"error_toast \"<>m   -> {\"error_toast\", m}
            \"success_toast \"<>m -> {\"success_toast\", m}
            \"warning_toast \"<>m -> {\"warning_toast\", m}
            m -> {\"logger \", m}
          end
          rendered = Mustache.render(rmessage, vars)
          RPCMessageHandler.log(rendered, channel)
          SequencerVM.tick(parent)
          {:noreply, parent}

        not_special ->
          rendered = Mustache.render(not_special, vars)
          RPCMessageHandler.log(rendered)
          SequencerVM.tick(parent)
          {:noreply, parent}
      end
    end

    def handle_cast({\"send_message\", _}, parent) do
      RPCMessageHandler.log(\"bad params\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  # catch all
  def create_node_instructions(%{"name" => name, "allowed_args" => [], "allowed_body_types" => allowed_body_types})
  when is_bitstring(name) and is_list(allowed_body_types) do
    "
    def handle_cast({#{name}, _}, parent) do
      Logger.debug(\"node #{name} is not implemented\")
      SequencerVM.tick(parent)
      {:noreply, parent}
    end
    "
  end

  def create_node_instructions(%{"name" => name, "allowed_args" => allowed_args, "allowed_body_types" => allowed_body_types})
  when is_bitstring(name) and is_list(allowed_args) and is_list(allowed_body_types) do
    b = Enum.reduce(allowed_args, "", fn(x, acc) -> acc <> "\"#{x}\" => #{x}, "end)
    args = String.slice(b, 0, String.length(b) - 2)
    "
    def #{name}( %{#{args}} ) do
      Logger.debug(\"node #{name} is not implemented\")
    end
    "
  end

  def create_arg_map(allowed_args) do
    b = Enum.reduce(allowed_args, "", fn(x, acc) -> acc <> "\"#{x}\" => #{x}, "end)
    String.slice(b, 0, String.length(b) - 2)
  end
end
