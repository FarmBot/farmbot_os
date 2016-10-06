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

  def execute(body, pid) when is_list(body) do
    for node <- body do # compile the ast
      RPCMessageHandler.log("Doing: #{Map.get(node, "kind")}")
      SequenceCommands.do_command({Map.get(node, "kind"), Map.get(node, "args")}, pid)
      Process.sleep(50)
    end
    GenServer.stop(pid)
  end

  def handle_call({:set_var, identifier, value}, _from, %{vars: vars, name: name}) do
    {:reply, :ok, %{vars: Map.put(vars, identifier, value), name: name} }
  end

  def handle_call({:get_var, identifier}, _from, %{vars: vars, name: name} ) do
    v = Map.get(vars, identifier, "unset")
    {:reply, v, %{vars: vars, name: name} }
  end

  def terminate(:normal, state) do
    RPCMessageHandler.log("Sequence: #{state.name} finished with state: #{inspect state}")
  end

  def terminate(reason, state) do
    RPCMessageHandler.log("Sequence: #{state.name} finished with error: #{inspect reason}")
  end

  def get_test_sequence(seq \\ "https://gist.githubusercontent.com/ConnorRigby/2fc571e50a356a4f44ba429e1f0753f2/raw/0d2dd7bb73b4aed87abdc4861f9b6a4a6304affb/sequence.json") do
    resp = HTTPotion.get(seq)
    Poison.decode!(resp.body)
  end

  def test_sync_sequences do
    s1 = get_test_sequence
    s2 = get_test_sequence("https://gist.githubusercontent.com/ConnorRigby/04d48076e9049ce6a2e09e8501bd6b6c/raw/61058eb0301a1bb69528e73ba679ce23d4953952/blah2.json")
    spawn fn -> do_sequence(s1) end
    Process.sleep(1000)
    spawn fn -> do_sequence(s2) end
  end
end
