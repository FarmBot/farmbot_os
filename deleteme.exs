defmodule Blah do

  def thing do
    yahoo_port = "ping yahoo.com"
    google_port = "ping google.com"
    top_port = Port.open({:spawn, yahoo_port}, [:binary])
    ping_port =  Port.open({:spawn, google_port}, [:binary])
    #<PORT234234>
    # {port, {:data, string}}
    check_port(yahoo_port, google_port)
  end

  def check_port(yahoo, google) do
    receive do
      {^yahoo, {:data, string}} -> IO.puts "got info from yahoo:  #{inspect string}"
      {^google, {:data, string}} -> IO.puts "got info from google: #{inspect string}"
    end
    check_port(yahoo, google)
  end
end
