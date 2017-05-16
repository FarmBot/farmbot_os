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

  def login(email \\ "admin@admin.com",
            pass  \\ "password123",
            url   \\ "http://localhost:3000") do
    use_cassette "good_login" do
      :ok = Auth.interim(email, pass, url)
      {:ok, token} = Auth.try_log_in
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
end
