# :os.cmd('shellinaboxd -t -b -d -s "/:root:root:/:wy60 -c /bin/sh"')

defmodule FFF do

  use GenServer

  def start_link do
     GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    args = [
      "-t",
      "-d",
      "--port=420"
    ]
    siab = System.find_executable("shellinaboxd")
    port_args = [
      :stream,
      :binary,
      :exit_status,
      :hide,
      :use_stdio,
      :stderr_to_stdout,
      args: args
    ]
    port = Port.open({:spawn_executable, siab}, port_args)
    {:ok, port}
  end

  def handle_info(:kill, port) do
    {:stop, :kill, port}
  end

  def handle_info({port, {:data, contents}}, _) do
    IO.puts "SIAB: #{contents}"
    {:noreply, port}
  end

  def handle_info({port, {:exit_status, exit_code}}, _) do
    IO.puts "EXITING SHELL IN A BOX: #{exit_code}"
    {:stop, exit_code, port}
  end

  def terminate(reason, port) do
    kill(port)
  end

  require IEx

  def kill(port) do
    # IEx.pry
    info = Port.info(port)
    if info do
      IO.puts "killing port"
      # send port, {self(), :close}
      System.cmd("kill", ["15", "#{info[:os_pid]}"])
    end
  end


end
