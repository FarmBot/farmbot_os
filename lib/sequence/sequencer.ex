defmodule Sequencer do
  require Logger

  def init(args) do
    initial_state = %{vars: %{}, name: args.name, bot_state: BotStatus.get_status, running: true}
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
    Process.flag(:trap_exit, true)
    spawn_link fn -> execute(body, pid) end
    pid
  end

  def execute(body, pid, kill\\ true) when is_list(body) do
    for node <- body do
      do_step(node,pid)
    end
    if(kill) do
      GenServer.stop(pid)
    end
  end

  def do_step(node, pid) do
    if(run_next_tick?(pid)) do
      RPCMessageHandler.log("Doing: #{Map.get(node, "kind")}")
      SequenceCommands.do_command(node, pid)
      Process.sleep(50)
    else
      Process.sleep(10)
      do_step(node,pid)
    end
  end

  def handle_call({:set_var, identifier, value}, _from, %{vars: vars, name: name, bot_state: bot_state, running: running}) do
    {:reply, :ok, %{vars: Map.put(vars, identifier, value), name: name, bot_state: bot_state, running: running} }
  end

  def handle_call({:get_var, identifier}, _from, %{vars: vars, name: name, bot_state: bot_state, running: running} ) do
    v = Map.get(vars, identifier, "unset")
    {:reply, v, %{vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_call(:get_all_vars, _from, %{vars: vars, name: name, bot_state: bot_state, running: running} ) do
    {:reply, vars |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end), %{vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_call(:pause, _from, %{vars: vars, name: name, bot_state: _bot_state, running: _running} ) do
    paused_status = BotStatus.get_status
    RPCMessageHandler.log("Pausing Sequence: #{name}")
    {:reply, paused_status, %{vars: vars, name: name, bot_state: paused_status, running: false} }
  end

  def handle_call(:tick?, _from, %{vars: vars, name: name, bot_state: bot_state, running: running} ) do
    {:reply, running, %{vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_cast(:resume, %{vars: vars, name: name, bot_state: paused_status, running: _running} ) do
    BotStatus.apply_status(paused_status)
    RPCMessageHandler.log("Resuming Sequence: #{name}")
    {:noreply, %{vars: vars, name: name, bot_state: BotStatus.get_status, running: true} }
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    msg = "Sequence failed because: #{inspect reason}"
    Logger.debug(msg)
    RPCMessageHandler.log(msg)
    {:noreply, state}
  end

  def run_next_tick?(pid) do
    GenServer.call(pid, :tick?)
  end

  def pause_sequence(pid) do
    GenServer.call(pid, :pause)
  end

  def resume_sequence(pid) do
    GenServer.cast(pid, :resume)
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

  def load_test do
    load_external_sequence("http://192.168.29.154:5050/test.json")
  end

  def load_test5 do
    load_external_sequence("http://192.168.29.154:5050/test5.json")
  end
end
