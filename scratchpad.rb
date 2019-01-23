# Farmbot.Helpers.load_local("./manifest.json")
# {:ok, pid} = Farmbot.FarmwareRuntime.start_link Asset.get_farmware_manifest("Farmware API Research")


require "pry"

Thread.new do
  puts get_rx_pipe()
end

def send_cs(msg)
  tx_pipe.puts(msg)
end

binding.pry
