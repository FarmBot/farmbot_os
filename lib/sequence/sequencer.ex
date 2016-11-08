defmodule SequencerVM do
  require Logger


  def start_link(sequence) do
    GenServer.start_link(__MODULE__,sequence)
  end

  def init(sequence) do
    tv = Map.get(sequence.args, "tag_version") || 0
    BotSync.sync()
    corpus_module = BotSync.get_corpus(tv)
    {:ok, instruction_set} = corpus_module.start_link(self())
    tick(self(), :done)
    initial_state =
      %{
        status: BotState.get_status,
        instruction_set: instruction_set,
        vars: %{},
        running: true,
        sequence: sequence,
        steps: {sequence.body, []}
       }
    {:ok, initial_state}
  end

  def handle_call({:set_var, identifier, value}, _from, state) do
    new_vars = Map.put(state.vars, identifier, value)
    new_state = Map.put(state, :vars, new_vars )
    {:reply, :ok, new_state }
  end

  def handle_call({:get_var, identifier}, _from, state ) do
    v = Map.get(state.vars, identifier, :error)
    {:reply, v, state }
  end

  def handle_call(:get_all_vars, _from, state ) do
    # Kind of dirty function to make mustache work properly.
    # Also possibly a huge memory leak.

    # get all of the local vars from the vm. # SUPER UNSAFE
    thing1 = state.vars |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)

    # put current position into the Map
    [x,y,z] = BotState.get_current_pos
    pins = BotState.get_status
    |> Map.get(:pins)
    |> Enum.reduce(%{}, fn( {key, %{mode: _mode, value: val}}, acc) ->
      # THIS IS SO UNSAFE
      Map.put(acc, String.to_atom("pin"<>key), val)
    end)
    thing2 = Map.merge( %{x: x, y: y, z: z }, pins)

    # gets a couple usefull things out of BotSync
    thing3 = List.first(BotSync.fetch
    |> Map.get(:users))
    |> Map.drop([:__struct__]) # This probably isnt correct

    # Combine all the things.
    all_things = Map.merge(thing1, thing2) |> Map.merge(thing3)
    {:reply, all_things , state}
  end

  def handle_call(:pause, _from, state) do
    {:reply, self(), Map.put(state, :running, false)}
  end

  def handle_call(thing, _from, state) do
    RPC.MessageHandler.log("#{inspect thing} is probably not implemented",
      [:warning_toast], [state.sequence.name])
    {:reply, :ok, state}
  end

  def handle_cast(:resume, state) do
    handle_info(:run_next_step, Map.put(state, :running, true))
  end

  # if the VM is paused
  def handle_info(:run_next_step, %{
          sequence: sequence,
          steps: steps,
          status: status,
          instruction_set: instruction_set,
          vars: vars,
          running: false
         })
  do
    {:noreply,
      %{status: status, sequence: sequence, steps: steps,
        instruction_set: instruction_set, vars: vars, running: false  }}
  end

  # if there is no more steps to run
  def handle_info(:run_next_step, %{
          status: status,
          sequence: sequence,
          instruction_set: instruction_set,
          vars: vars,
          running: running,
          steps: {[], finished_steps}
         })
  do
    Logger.debug("sequence done")
    RPC.MessageHandler.log("Sequence Complete", [], [sequence.name])
    send(SequenceManager, {:done, self(), sequence})
    Logger.debug("Stopping VM")
    {:noreply,
      %{status: status,
        sequence: sequence,
        steps: {[], finished_steps},
        instruction_set: instruction_set,
        vars: vars,
        running: running  }}
  end

  # if there are more steps to run
  def handle_info(:run_next_step, %{
          status: status,
          instruction_set: instruction_set,
          vars: vars,
          running: true,
          sequence: sequence,
          steps: {more_steps, finished_steps} })
  do
    ast_node = List.first(more_steps)
    kind = Map.get(ast_node, "kind")
    Logger.debug("doing: #{kind}")
    RPC.MessageHandler.log("Doing step: #{kind}", [], [sequence.name])
    GenServer.cast(instruction_set, {kind, Map.get(ast_node, "args") })
    {:noreply, %{
            status: status,
            sequence: sequence,
            steps: {more_steps -- [ast_node], finished_steps ++ [ast_node]},
            instruction_set: instruction_set,
            vars: vars,
            running: true }}
  end

  def handle_info({:error, error}, state) do
    RPC.MessageHandler.log("ERROR: #{inspect(error)}", [:error], [state.sequence.name])
    :step_fail
  end

  # the last command was successful
  def tick(vm, :done) do
    Process.send_after(vm, :run_next_step, 100)
  end

  def tick(vm, error) do
    Process.send_after(vm, {:error, error}, 100)
  end

  def terminate(:normal, state) do
    GenServer.stop(state.instruction_set, :normal)
  end

  def terminate({:bad_return_value, :step_fail}, state) do
    Logger.debug("VM Died!")
    RPC.MessageHandler.log("Sequence Finished with errors! (probably in E_STOP MODE)", [:error_toast], [state.sequence.name])
    GenServer.stop(state.instruction_set, :normal)
  end

  def terminate(reason, state) do
    Logger.debug("VM Died")
    RPC.MessageHandler.log("Sequence Finished with errors! #{inspect reason}", [:error_toast], ["Sequencer"])
    GenServer.stop(state.instruction_set, :normal)
  end
end
