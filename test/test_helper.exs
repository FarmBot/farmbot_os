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
