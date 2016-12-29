ExUnit.start
StateDebugger.start
IO.puts "deleting config and secret"
File.rm_rf! "/tmp/config.json"
File.rm_rf! "/tmp/secret"
