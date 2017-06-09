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

defmodule Farmbot.Test.Helpers.SerialTemplate do
  alias Farmbot.Serial.Handler
  alias Farmbot.Test.SerialHelper
  use ExUnit.CaseTemplate

  defp wait_for_serial(context) do
    unless Handler.available?(context) do
      # IO.puts "waiting for serial..."
      Process.sleep(100)
      wait_for_serial(context)
    end
  end

  setup_all do
    {{hand, firm}, slot, context} = SerialHelper.setup_serial()
    wait_for_serial(context)

     on_exit fn() -> SerialHelper.teardown_serial({hand, firm}, slot) end
     [cs_context: context, serial_handler: hand, firmware_sim: firm]
  end
end

defmodule Farmbot.Test.Helpers do
  alias Farmbot.Database, as: DB

  def login(_), do: raise "FIXME!"

  def random_file(dir \\ "fixture/api_fixture"),
    do: File.ls!(dir) |> Enum.random

  def read_json(:random) do
     random_file() |> read_json
  end

  def read_json("/" <> file), do: read_json(file)

  def read_json(file) do
    "fixture/api_fixture/#{file}"
    |> File.read!()
    |> Poison.decode!
  end

  def seed_db(context, module, json) do
    tagged = Enum.map(json, fn(item) ->
      tag_item(item, module)
    end)
    :ok = DB.commit_records(tagged, context, module)
  end

  def tag_item(map, tag) do
    updated_map =
      map
      |> Enum.map(fn({key, val}) ->  {String.to_atom(key), val} end)
      |> Map.new()
    struct(tag, updated_map)
  end
end

defmodule Farmbot.Test.Helpers.Checkup do

  defp do_exit do
    Mix.shell.info([:red, "Farmbot isn't alive. Not testing."])
    System.halt(255)
  end

  def checkup do
    fb_pid = Process.whereis(Farmbot.Supervisor) || do_exit()
    Process.alive?(fb_pid)                       || do_exit()
    Process.sleep(500)
    checkup()
  end
end

Mix.shell.info [:green, "Checking init and stuff"]

spawn Farmbot.Test.Helpers.Checkup, :checkup, []

Mix.shell.info [:green, "Starting ExCoveralls"]
{:ok, _} = Application.ensure_all_started(:excoveralls)

# Mix.shell.info [:green, "Starting FarmbotSimulator"]
# :ok = Application.ensure_started(:farmbot_simulator)

Process.sleep(100)

Mix.shell.info [:green, "deleting config and secret"]
File.rm_rf! "/tmp/config.json"
File.rm_rf! "/tmp/secret"
File.rm_rf! "/tmp/farmware"

Mix.shell.info [:green, "Setting up faker"]
Faker.start

Mix.shell.info [:green, "Setting up vcr"]
ExVCR.Config.cassette_library_dir("fixture/cassettes")

Mix.shell.info [:green, "removeing logger"]
Logger.remove_backend Logger.Backends.FarmbotLogger
# Farmbot.DebugLog.filter(:all)

{:ok, pid} = Farmbot.Test.SerialHelper.start_link()
Process.link(pid)
ExUnit.start
