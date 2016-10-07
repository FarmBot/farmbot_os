defmodule Sequencer do
  require Logger

  def init(args) do
    initial_state = %{vars: %{}, name: args.name}
    {:ok, initial_state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def do_sequence(%{"id" => _sequence_id,
  "device_id" => _device_id, "name" => name,
  "kind" => "sequence", "color" => _color,
  "args" => _args, "body" => body})  do
    {:ok, pid} = start_link(%{name: name})
    Logger.debug("Starting Sequence: #{name}")
    RPCMessageHandler.log("Starting Sequence: #{name}")
    execute(body, pid)
  end

  def execute(body, pid, kill\\ true) when is_list(body) do
    for node <- body do # compile the ast
      RPCMessageHandler.log("Doing: #{Map.get(node, "kind")}")
      SequenceCommands.do_command({Map.get(node, "kind"), Map.get(node, "args")}, pid)
      Process.sleep(50)
    end
    if(kill) do
      GenServer.stop(pid)
    end
  end

  def handle_call({:set_var, identifier, value}, _from, %{vars: vars, name: name}) do
    {:reply, :ok, %{vars: Map.put(vars, identifier, value), name: name} }
  end

  def handle_call({:get_var, identifier}, _from, %{vars: vars, name: name} ) do
    v = Map.get(vars, identifier, "unset")
    {:reply, v, %{vars: vars, name: name} }
  end

  def handle_call(:get_all_vars, _from, %{vars: vars, name: name} ) do
    {:reply, vars |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end), %{vars: vars, name: name} }
  end

  def terminate(:normal, state) do
    RPCMessageHandler.log("Sequence: #{state.name} finished with state: #{inspect state}")
  end

  def terminate(reason, state) do
    RPCMessageHandler.log("Sequence: #{state.name} finished with error: #{inspect reason}")
  end

  def load_external_sequence(url) do
    resp = HTTPotion.get(url)
    Poison.decode!(resp.body)
  end
end
