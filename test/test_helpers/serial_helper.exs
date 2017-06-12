defmodule Farmbot.Test.SerialHelper do
  use GenServer
  alias Farmbot.Context

  def setup_serial do
    context = Context.new()
    {ttya, ttyb} = slot = get_slot()
    {:ok, hand} = Farmbot.Serial.Handler.start_link(context, ttyb, [])
    {:ok, firm} = FirmwareSimulator.start_link(ttya, [])
    context = %{context | serial: hand}
    # IO.puts "claiming slot: #{inspect slot}"
    {{hand, firm}, slot, context}
  end

  def teardown_serial({hand, firm}, slot) do
    # IO.puts "releaseing slot: #{inspect slot}"
    spawn fn() ->
      GenServer.stop(hand, :shutdown)
      GenServer.stop(firm, :shutdown)

    end
    done_with_slot(slot)
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_slot do
    GenServer.call(__MODULE__, :get_slot, :infinity)
  end

  def done_with_slot(slot) do
    GenServer.call(__MODULE__, {:done_with_slot, slot})
  end

  def init([]) do
    slots = [{"tnt0", "tnt1"}, {"tnt2", "tnt3"}, {"tnt4", "tnt5"}, {"tnt6", "tnt7"}]
    slot_map = Map.new(slots, fn(slot) -> {slot, nil} end)
    {:ok, %{slots: slot_map, waiting_for_slots: []}}
  end

  def handle_call(:get_slot, from, state) do
    slot = Enum.find_value(state.slots, fn({slot, user}) ->
      unless user do
        slot
      end
    end)

    if slot do
      {:reply, slot, %{state | slots: %{state.slots | slot => from}}}
    else
      new_waiting = [from | state.waiting_for_slots]
      {:noreply, %{state | waiting_for_slots: new_waiting}}
    end
  end

  def handle_call({:done_with_slot, slot}, from, state) do
    case Enum.reverse state.waiting_for_slots do
      [next_in_line | rest] ->
        GenServer.reply(next_in_line, slot)
        {:reply, :ok, %{state | waiting_for_slots: rest, slots: %{state.slots | slot => from}}}
      [] ->
        {:reply, :ok, %{state | slots: %{state.slots | slot => nil}}}
    end
  end
end
