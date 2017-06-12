Mix.shell.info [:green, "Compiling test helpers."]

test_lib_dir = "test/test_helpers"
File.ls!(test_lib_dir)
  |> Enum.filter(fn(filename) -> Path.extname(filename) == ".exs" end)
  |> Enum.all?(fn(f) ->
    Mix.shell.info [:green, "Compiling #{f}"]
    Code.require_file("#{test_lib_dir}/#{f}")
  end) || Mix.raise "Compile error on helpers."

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
