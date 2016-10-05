defmodule Mix.Tasks.Curl do
  use Mix.Task

  @shortdoc "Does an HTTP request to the Pi to give it new firmware."
  @preferred_cli_env "prod"

  def run(ip_addr) do
    System.cmd("curl", [ "-T",
                         "_images/rpi3/fw.fw",
                         "http://#{ ip_addr }:8988/firmware",
                         "-H",
                         "Content-Type: application/x-firmware", 
                         "-H",
                         "X-Reboot: true" ])
  end
end
