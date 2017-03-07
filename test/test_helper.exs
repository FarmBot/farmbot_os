ExUnit.start
IO.puts "deleting config and secret"
File.rm_rf! "/tmp/config.json"
File.rm_rf! "/tmp/secret"
File.rm_rf! "/tmp/farmware"
Faker.start
ExVCR.Config.cassette_library_dir("fixture/cassettes")
:ok = Logger.remove_backend Farmbot.Logger
