defmodule Sequencer do
  require Logger

  def init(%{name: name, tag_version: tag_version}) do
    resp = HTTPotion.get("http://192.168.29.167:3000/api/corpuses")
    instruction_set = Poison.decode!(resp.body) |> List.first |> SequenceInstructionSet.create_instruction_set
    initial_state =
      %{vars: %{},
        name: name,
        tag_version: tag_version, instruction_set: instruction_set,
        bot_state: BotStatus.get_status,
        running: true}
    {:ok, initial_state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # im not particularly proud of this function.
  def do_sequence(sequence) do
    BotSync.sync
    required_keys = ["body", "args", "name"]
    case Enum.all?(required_keys, fn(key) -> Map.has_key?(sequence, key) end) do
      true ->
        args = Map.get(sequence, "args")
        tag_version = Map.get(args, "tag_version") || 0
        body = Map.get(sequence, "body")
        name = Map.get(sequence, "name")
        {:ok, pid} = start_link(%{name: name, tag_version: tag_version})
        spawn_link fn -> execute(body, pid) end
        {:ok, pid}
    end
  end

  def execute(body, pid) when is_list(body) and is_pid(pid) do
    do_steps(body,pid)
  end

  def do_steps([], pid) do
    GenServer.stop(pid)
  end

  def do_steps(body, pid) when is_list(body) do
    if(BotStatus.busy?) do
      Process.sleep(10)
      do_steps(body, pid)
    end
    if(run_next_tick?(pid)) do
      node = List.first(body)
      RPCMessageHandler.log("Doing: #{Map.get(node, "kind")}")
      # SequenceCommands.do_command(node, pid)
      GenServer.cast(pid, {:do_step, node})
      Process.sleep(200)
      do_steps(body -- [node], pid)
    else
      Process.sleep(10)
      do_steps(body, pid)
    end
  end

  def handle_call({:set_var, identifier, value}, _from, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: bot_state, running: running}) do
    {:reply, :ok, %{tag_version: tag_version, instruction_set: instruction_set, vars: Map.put(vars, identifier, value), name: name, bot_state: bot_state, running: running} }
  end

  def handle_call({:get_var, identifier}, _from, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: bot_state, running: running} ) do
    v = Map.get(vars, identifier, "unset")
    {:reply, v, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_call(:get_all_vars, _from, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: _nope, running: running} ) do
    bot_state = BotStatus.get_status
    thing1 = vars |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)
    thing2 = bot_state |> Enum.reduce(%{}, fn ({key, val}, acc) ->
      cond do
        is_bitstring(key) -> Map.put(acc, String.to_atom(key), val)
        is_atom(key) -> Map.put(acc, key, val)
      end
    end)
    username = List.first(Map.get(BotSync.fetch, "users")) |> Map.get("name")
    bot_name = Map.get(BotSync.fetch, "device") |> Map.get("name")
    thing3 = %{username: username, bot_name: bot_name}

    all_things = Map.merge(thing1, thing2) |> Map.merge(thing3)
    {:reply, all_things , %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_call(:pause, _from, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: _bot_state, running: true} ) do
    paused_status = BotStatus.get_status
    RPCMessageHandler.log("Pausing Sequence: #{name}")
    {:reply, paused_status, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: paused_status, running: false} }
  end

  def handle_call(:tick?, _from, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: bot_state, running: running} ) do
    {:reply, running, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_cast(:resume, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: paused_status, running: false} ) do
    BotStatus.apply_status(paused_status)
    RPCMessageHandler.log("Resuming Sequence: #{name}")
    {:noreply, %{vars: vars, name: name, bot_state: BotStatus.get_status, running: true} }
  end

  def handle_cast({:do_step, node}, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: paused_status, running: running}) do
    GenServer.call(instruction_set, node)
    {:noreply, %{tag_version: tag_version, instruction_set: instruction_set, vars: vars, name: name, bot_state: paused_status, running: running}}
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
    GenServer.call(SequenceManager, {:done, self()})
    RPCMessageHandler.log("Sequence: #{state.name} finished")
  end

  def terminate(reason, state) do
    Logger.debug("Something weird happened")
    RPCMessageHandler.log("Sequence: #{state.name} finished with error: #{inspect reason}")
    GenServer.call(SequenceManager, {:done, self()})
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
