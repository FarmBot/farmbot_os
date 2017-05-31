defmodule Farmbot.Test.HTTPHelper do
  alias HTTPoison.{
    # Response,
    AsyncResponse,
    AsyncChunk,
    AsyncStatus,
    AsyncHeaders,
    AsyncEnd,
    # Error,
    # AsyncRedirect
  }
  import Mock

  defmodule FakeAsync do

    defp ensure_mock(%{headers: _header, body: _body, status_code: _code}), do: :ok
    defp ensure_mock(_), do: raise "mock is invalid, please supply: [:headers, :body, :code]"

    def do_fake_request({_method, _url, _body, _headers, _options} = request, mock) do
      ensure_mock(mock)
      ref = make_ref()
      spawn __MODULE__, :stage_one, [request, ref, mock]
      %AsyncResponse{id: ref}
    end

    def stage_one({_method, _url, _body, _headers, options} = request, ref, mock) do
      s2  = Keyword.fetch!(options, :stream_to)
      code = mock.status_code
      msg = %AsyncStatus{id: ref, code: code}
      send s2, msg
      stage_two(request, ref, mock)
    end

    def stage_two({_method, _url, _body, _headers, options} = request, ref, mock) do
      s2  = Keyword.fetch!(options, :stream_to)
      headers = mock.headers
      msg = %AsyncHeaders{headers: headers, id: ref}
      send s2, msg
      stage_three(request, ref, mock)
    end

    def stage_three({_method, _url, _body, _headers, options} = request, ref, mock) do
      body = mock.body
      s2  = Keyword.fetch!(options, :stream_to)
      msg = %AsyncChunk{chunk: body, id: ref}
      send s2, msg
      stage_four(request, ref, mock)
    end

    def stage_four({_method, _url, _body, _headers, options}, ref, _mock) do
      s2  = Keyword.fetch!(options, :stream_to)
      msg = %AsyncEnd{id: ref}
      send s2, msg
      :ok
    end
  end
end

defmodule Farmbot.Tests.HTTPTemplate do
  use ExUnit.CaseTemplate
  alias Farmbot.{Context, HTTP, Auth}
  alias Farmbot.Test.HTTPHelper
  import Mock

  defmacro mock_http(mock, fun) do

    quote do
      with_mock HTTPoison, [request!: fn(method, url, body, headers, options) ->
        request = {method, url, body, headers, options}
        HTTPHelper.FakeAsync.do_fake_request(request, unquote(mock))
      end] do
        unquote(fun).()
      end
    end

  end
  def fake_token do
    %{"encoded" => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1p" <>
                   "bkBhZG1pbi5jb20iLCJpYXQiOjE0OTUwMzIwMTAsImp0aSI6ImUyM" <>
                   "2YyNzI0LTAyZWMtNDk2OC1iNjc5LWI4MTQ0YjI3N2JiZiIsImlzcy" <>
                   "I6Ii8vMTkyLjE2OC4yOS4xNjU6MzAwMCIsImV4cCI6MTQ5ODQ4ODA" <>
                   "xMCwibXF0dCI6IjE5Mi4xNjguMjkuMTY1Iiwib3NfdXBkYXRlX3Nl" <>
                   "cnZlciI6Imh0dHBzOi8vYXBpLmdpdGh1Yi5jb20vcmVwb3MvZmFyb" <>
                   "WJvdC9mYXJtYm90X29zL3JlbGVhc2VzL2xhdGVzdCIsImZ3X3VwZG" <>
                   "F0ZV9zZXJ2ZXIiOiJodHRwczovL2FwaS5naXRodWIuY29tL3JlcG9" <>
                   "zL0Zhcm1ib3QvZmFybWJvdC1hcmR1aW5vLWZpcm13YXJlL3JlbGVh" <>
                   "c2VzL2xhdGVzdCIsImJvdCI6ImRldmljZV84In0.UcBgq4pxoXeR6" <>
                   "TYv9lYd90LAlGczZMjuvqT1Yc4R8xIk_Jy6bumhq7mI-Hoi9i"     <>
                   "KBhPU3XMpifXoIyqb1UdC1MBJyHMpPYjZoJLmm4v3XEug_rTu4Rca" <>
                   "O7r_r1dZAh2C5TPVXBydcDe02loGC4_YmQPwWixhqJO_6vFF7JEDH" <>
                   "ir4bihbdfV-P4uZhpUcw-I1Eht4zCMjlmWaL5xcKUdSf-TuSQGNi0" <>
                   "Ib0GkZs2wXan2bgv_wBfFEaZ4vmoZO1NM43jaykDssOaxP9hN7FKD" <>
                   "dJ4mXL7r9XS7KtXpVQPycUYsfr-lPvid9cfKQFv-STakiDot8uGOY" <>
                   "r1CH6I9erQMlhnQ",
      "unencoded" => %{
          "bot"              => "device_8",
          "exp"              => 1498488010,
          "fw_update_server" => "https://api.github.com/repos/Farmbot/farmb" <>
                                "ot-arduino-firmware/releases/latest",
          "iat"              => 1495032010,
          "iss"              => "//192.168.29.165:3000",
          "jti"              => "e23f2724-02ec-4968-b679-b8144b277bbf",
          "mqtt"             => "192.168.29.165",
          "os_update_server" => "https://api.github.com/repos/farmbot/farmb" <>
                                "ot_os/releases/latest",
          "sub"              => "admin@admin.com"
        }
      }
  end

  def replace_auth_state(context) do
    token = Farmbot.Token.create! fake_token()
    :sys.replace_state(context.auth, fn(old) ->
      %{old | token: token}
    end)
  end

  def replace_http_state(context) do
    :sys.replace_state(context.http, fn(old) ->
      new_context = %{old.context | auth: context.auth}
      %{old | context: new_context}
    end)
  end

  def mock_api(mock, context, fun) do
    replace_auth_state(context)
    replace_http_state(context)
    mock_http(mock, fun)
  end

  using do
    quote do
      import Farmbot.Tests.HTTPTemplate
      import Mock
    end
  end

  setup_all do
    context = Context.new
    {:ok, http} = HTTP.start_link(context, [])
    context = %{context | http: http}
    {:ok, auth} = Auth.start_link(context, [])
    context = %{context | auth: auth}
    [cs_context: context]
  end
end

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
Farmbot.DebugLog.filter(:all)

{:ok, pid} = Farmbot.Test.SerialHelper.start_link()
Process.link(pid)
ExUnit.start
