Mix.shell.info [:green, "Starting ExCoveralls"]
{:ok, _} = Application.ensure_all_started(:excoveralls)

ExUnit.start

Mix.shell.info [:green, "Starting FarmbotSimulator"]
:ok = Application.ensure_started(:farmbot_simulator)

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

Farmbot.DebugLog.filter(Farmbot.Serial.Handler)

defmodule Farmbot.TestHelpers do
  alias Farmbot.Auth
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Farmbot.Database, as: DB

  def login(auth, creds \\ nil) do
    creds = creds || %{
      email:  "admin@admin.com",
      pass:  "password123",
      url:  "http://localhost:3000"
    }
    use_cassette "good_login" do
      :ok = Auth.interim(auth, creds.email, creds.pass, creds.url)
      {:ok, token} = Auth.try_log_in(auth)
      token
    end
  end

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

  def seed_db(pid, module, json) do
    tagged = Enum.map(json, fn(item) ->
      tag_item(item, module)
    end)
    :ok = DB.commit_records(tagged, pid, module)
  end

  def tag_item(map, tag) do
    updated_map =
      map
      |> Enum.map(fn({key, val}) ->  {String.to_atom(key), val} end)
      |> Map.new()
    struct(tag, updated_map)
  end
end
