defmodule SequencerVM do
  require Logger

  def test(id \\ 3) do
    BotSync.sync
    resp = HTTPotion.get("http://192.168.29.167:3000/api/corpuses")
    Poison.decode!(resp.body) |> List.first |> SequenceInstructionSet.create_instruction_set
    sequence = BotSync.get_sequence(id) |> Map.merge( %{"args" => %{"tag_version" => 0}})
    start_link sequence
  end

  def start_link(sequence) do
    GenServer.start_link(__MODULE__,sequence)
  end

  def init(sequence) do
    body = Map.get(sequence, "body")
    args = Map.get(sequence, "args")
    tv = Map.get(args, "tag_version") || 0
    corpus = Module.concat(SiS, "Corpus_#{tv}")
    {:ok, instruction_set} = corpus.start_link(self())
    status = BotStatus.get_status
    tick(self())
    initial_state =
      %{
        status: status,
        body: body,
        args: %{},
        instruction_set: instruction_set
       }
    {:ok, initial_state}
  end

  def handle_info(:run_next_step, %{
          status: status,
          body: [],
          args: args,
          instruction_set: instruction_set
         })
  do
    Logger.debug("sequence done")
    {:noreply, %{status: status, body: [], args: args, instruction_set: instruction_set }}
  end

  def handle_info(:run_next_step, %{
          status: status,
          body: body,
          args: args,
          instruction_set: instruction_set
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
            instruction_set: instruction_set
           }}
  end

  def tick(vm) do
    Process.send_after(vm, :run_next_step, 100)
  end

end
