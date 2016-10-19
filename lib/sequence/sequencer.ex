defmodule SequencerVM do
  require Logger


  def start_link(sequence) do
    BotSync.sync
    GenServer.start_link(__MODULE__,sequence)
  end

  def init(sequence) do
    body = Map.get(sequence, "body")
    args = Map.get(sequence, "args")
    tv = Map.get(args, "tag_version") || 0
    BotSync.sync()
    corpus_module = BotSync.get_corpus(tv)
    {:ok, instruction_set} = corpus_module.start_link(self())
    status = BotStatus.get_status
    tick(self())
    initial_state =
      %{
        status: status,
        body: body,
        args: %{},
        instruction_set: instruction_set,
        vars: %{}
       }
    {:ok, initial_state}
  end

  def handle_call({:set_var, identifier, value}, _from, state) do
    new_vars = Map.put(state.vars, identifier, value)
    new_state = Map.put(state, :vars, new_vars )
    {:reply, :ok, new_state }
  end

  def handle_call({:get_var, identifier}, _from, state ) do
    v = Map.get(state.vars, identifier, "unset")
    {:reply, v, state }
  end

  def handle_call(:get_all_vars, _from, state ) do
    bot_state = BotStatus.get_status
    thing1 = state.vars |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)
    thing2 = bot_state |> Enum.reduce(%{}, fn ({key, val}, acc) ->
      cond do
        is_bitstring(key) -> Map.put(acc, String.to_atom(key), val)
        is_atom(key) -> Map.put(acc, key, val)
      end
    end)
    thing3v = List.first Map.get(BotSync.fetch, "users")
    thing3 = thing3v |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)
    all_things = Map.merge(thing1, thing2) |> Map.merge(thing3)
    {:reply, all_things , state }
  end

  def handle_call(thing, _from, state) do
    RPCMessageHandler.log("#{inspect thing} is probably not implemented")
    {:reply, :ok, state}
  end

  def handle_info(:run_next_step, %{
          status: status,
          body: [],
          args: args,
          instruction_set: instruction_set,
          vars: vars
         })
  do
    Logger.debug("sequence done")
    send(SequenceManager, {:done, self()})
    Logger.debug("Stopping VM")
    {:noreply, %{status: status, body: [], args: args, instruction_set: instruction_set, vars: vars }}
  end

  def handle_info(:run_next_step, %{
          status: status,
          body: body,
          args: args,
          instruction_set: instruction_set,
          vars: vars
         })
  do
    node = List.first(body)
    kind = Map.get(node, "kind")
    Logger.debug("doing: #{kind}")
    GenServer.cast(instruction_set, {kind, Map.get(node, "args") })
    {:noreply, %{
            status: status,
            body: body -- [node],
            args: args,
            instruction_set: instruction_set,
            vars: vars
           }}
  end

  def tick(vm) do
    Process.send_after(vm, :run_next_step, 100)
  end

  def terminate(:normal, state) do
    RPCMessageHandler.log("Sequence Finished without errors!", ["success_toast", "ticker"])
    GenServer.stop(state.instruction_set, :normal)
  end

  def terminate(reason, state) do
    Logger.debug("VM Died: #{inspect reason}")
    RPCMessageHandler.log("Sequence Finished with errors! #{inspect reason}", "error_toast")
    GenServer.stop(state.instruction_set, :normal)
    IO.inspect state
  end
end
