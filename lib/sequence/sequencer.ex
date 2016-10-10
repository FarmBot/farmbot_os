defmodule Sequencer do
  require Logger

  def init(args) do
    initial_state = %{vars: %{}, name: args.name, bot_state: BotStatus.get_status, running: true}
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
        body = Map.get(sequence, "body")
        name = Map.get(sequence, "name")
        case SequenceValidator.validate(args, body) do
          {:valid, warnings} ->
            RPCMessageHandler.log("Sequence Valid")
            for warning <- warnings do
              Logger.debug("Validator warning: #{inspect warning}")
              RPCMessageHandler.log("Validator warning: #{inspect warning}")
            end
            {:ok, pid} = start_link(%{name: name})
            Process.flag(:trap_exit, true)
            msg = "Starting Sequence: #{name}"
            Logger.debug(msg)
            RPCMessageHandler.log(msg)
            spawn_link fn -> execute(body, pid) end
            {:ok, pid}
          {:error, reason} ->
            Logger.debug("Couldn't start sequence: #{inspect reason}")
            RPCMessageHandler.log("Couldn't start sequence: #{inspect reason}")
            {:error, reason}
          _ ->
            Logger.debug("Couldn't start sequence: unknown error")
            RPCMessageHandler.log("Couldn't start sequence: unknown error")
            {:error, :unknown}
        end
      false ->
        Logger.debug("Missing key. Sequence invalid")
    end
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
    thing1 = vars |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)
    thing2 = bot_state |> Enum.reduce(%{}, fn ({key, val}, acc) ->
      cond do
        is_bitstring(key) -> Map.put(acc, String.to_atom(key), val)
        is_atom(key) -> Map.put(acc, key, val)
      end
    end)
    thing3v = List.first Map.get(BotSync.fetch, "users")
    thing3 = thing3v |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)
    all_things = Map.merge(thing1, thing2) |> Map.merge(thing3)
    {:reply, all_things , %{vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_call(:pause, _from, %{vars: vars, name: name, bot_state: _bot_state, running: true} ) do
    paused_status = BotStatus.get_status
    RPCMessageHandler.log("Pausing Sequence: #{name}")
    {:reply, paused_status, %{vars: vars, name: name, bot_state: paused_status, running: false} }
  end

  def handle_call(:tick?, _from, %{vars: vars, name: name, bot_state: bot_state, running: running} ) do
    {:reply, running, %{vars: vars, name: name, bot_state: bot_state, running: running} }
  end

  def handle_cast(:resume, %{vars: vars, name: name, bot_state: paused_status, running: false} ) do
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
    GenServer.call(SequenceManager, {:done, self()})
    RPCMessageHandler.log("Sequence: #{state.name} finished")
  end

  def terminate(reason, state) do
    GenServer.call(SequenceManager, {:done, self()})
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
