defmodule Mix.Tasks.Farmbot.Upload do
  use Mix.Task
  @shortdoc "Uploads a file to a url"
  def run(args) do
    ip_address = System.get_env("FARMBOT_IP")
    || List.first(args)
    || "192.168.29.186" # I get to do this because i own it.
    curl_args = [
      "-T", "_images/rpi3/farmbot.fw",
      "http://#{ip_address}:8988/firmware",
      "-H", "Content-Type: application/x-firmware",
      "-H", "X-Reboot: true"]
    IO.puts("Starting upload...")
    Mix.Tasks.Farmbot.Curl.run(curl_args)
  end
end

defmodule Mix.Tasks.Farmbot.Curl do
  use Mix.Task
  @shortdoc "Uploads an image to a development target"
  def run(args) do
    args = args ++
    [ "-#" ] # CURL OPTIONS
    Port.open({:spawn_executable, "/usr/bin/curl"},
              [{:args, args},
               :stream,
               :binary,
               :exit_status,
               :hide,
               :use_stdio,
               :stderr_to_stdout])
     handle_output
  end

  def handle_output do
    receive do
      info -> handle_info(info)
    end
  end

  def handle_info({port, {:data, << <<35>>, _ :: size(568), " 100.0%">>}}) do # LAWLZ
    IO.puts("\nDONE")
    Port.close(port)
  end

  def handle_info({port, {:data, << "\r", <<35>>, _ :: size(568), " 100.0%">>}}) do # LAWLZ
    IO.puts("\nDONE")
    Port.close(port)
  end

  def handle_info({_port, {:data, << <<35>>, <<_ :: binary>> >>}}) do
    IO.write("#")
    handle_output
  end

  def handle_info({_port, {:data, << "\n", <<35>>, <<_ :: binary>> >>}}) do
    IO.write("#")
    handle_output
  end

  def handle_info({_port, {:data, << "\r", <<35>>, <<_ :: binary>> >>}}) do
    IO.write("#")
    handle_output
  end

  def handle_info({_port, {:data, _data}}) do
    # IO.puts(data)
    handle_output
  end

  def handle_info({_port, {:exit_status, 7}}) do
    IO.puts("\nCOULD NOT CONNECT TO DEVICE!")
  end

  def handle_info({_port, {:exit_status, _status}}) do
    IO.puts("\nDONE")
  end
end
